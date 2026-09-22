pub mod domain;
use axum::{
    Json, Router,
    extract::{ConnectInfo, DefaultBodyLimit, State, rejection::JsonRejection},
    http::{HeaderMap, StatusCode},
    response::{IntoResponse, Response},
    routing::{delete, get, post},
};
use base64::{Engine, engine::general_purpose::URL_SAFE_NO_PAD};
use domain::{Operation, Payload, Registration};
use serde_json::{Value, json};
use sha2::{Digest, Sha256};
use sqlx::{
    Row, Sqlite, SqlitePool, Transaction,
    sqlite::{SqliteConnectOptions, SqliteJournalMode, SqlitePoolOptions, SqliteSynchronous},
};
use std::{
    collections::HashMap,
    net::SocketAddr,
    str::FromStr,
    sync::{Arc, Mutex},
    time::{Duration, Instant},
};
use subtle::ConstantTimeEq;

pub type Result<T> = std::result::Result<T, ApiError>;
pub struct ApiError {
    status: StatusCode,
    code: &'static str,
    expected: Option<i64>,
    retry: Option<u64>,
}
impl ApiError {
    fn new(status: StatusCode, code: &'static str) -> Self {
        Self {
            status,
            code,
            expected: None,
            retry: None,
        }
    }
    pub fn invalid(code: &'static str) -> Self {
        Self::new(StatusCode::UNPROCESSABLE_ENTITY, code)
    }
    fn conflict(code: &'static str) -> Self {
        Self::new(StatusCode::CONFLICT, code)
    }
    fn auth() -> Self {
        Self::new(StatusCode::UNAUTHORIZED, "unauthorized")
    }
}
impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let mut error = json!({"code":self.code,"message":self.code,"request_id":uuid::Uuid::new_v4().to_string()});
        if let Some(seq) = self.expected {
            error["expected_seq"] = json!(seq);
        }
        let mut response = (self.status, Json(json!({"error":error}))).into_response();
        if let Some(seconds) = self.retry {
            response.headers_mut().insert(
                "Retry-After",
                seconds.to_string().parse().expect("integer header"),
            );
        }
        response
    }
}
impl From<sqlx::Error> for ApiError {
    fn from(_: sqlx::Error) -> Self {
        Self::new(StatusCode::SERVICE_UNAVAILABLE, "database_unavailable")
    }
}
fn parse_json(body: std::result::Result<Json<Value>, JsonRejection>) -> Result<Value> {
    body.map(|Json(v)| v).map_err(|e| {
        ApiError::new(
            e.status(),
            if e.status() == StatusCode::PAYLOAD_TOO_LARGE {
                "body_too_large"
            } else {
                "invalid_json"
            },
        )
    })
}
fn now() -> i64 {
    chrono::Utc::now().timestamp_millis()
}
#[derive(Clone)]
pub struct Limits {
    pub registrations: u32,
    pub operations_per_minute: u32,
    pub burst: u32,
    pub snapshots: u32,
}
impl Default for Limits {
    fn default() -> Self {
        Self {
            registrations: 10,
            operations_per_minute: 120,
            burst: 60,
            snapshots: 6,
        }
    }
}
struct Bucket {
    tokens: f64,
    last: Instant,
}
#[derive(Clone)]
pub struct AppState {
    pub pool: SqlitePool,
    limits: Limits,
    buckets: Arc<Mutex<HashMap<String, Bucket>>>,
}
impl AppState {
    pub async fn connect(url: &str, limits: Limits) -> std::result::Result<Self, sqlx::Error> {
        let options = SqliteConnectOptions::from_str(url)?
            .create_if_missing(true)
            .journal_mode(SqliteJournalMode::Wal)
            .foreign_keys(true)
            .synchronous(SqliteSynchronous::Full)
            .busy_timeout(Duration::from_secs(5));
        let pool = SqlitePoolOptions::new()
            .max_connections(1)
            .connect_with(options)
            .await?;
        sqlx::migrate!().run(&pool).await?;
        Ok(Self {
            pool,
            limits,
            buckets: Arc::new(Mutex::new(HashMap::new())),
        })
    }
    fn limit(&self, key: String, capacity: u32, period: f64) -> Result<()> {
        let mut buckets = self.buckets.lock().map_err(|_| {
            ApiError::new(StatusCode::SERVICE_UNAVAILABLE, "rate_limiter_unavailable")
        })?;
        let now = Instant::now();
        buckets.retain(|_, b| now.duration_since(b.last).as_secs() < 3600);
        if buckets.len() >= 10000 && !buckets.contains_key(&key) {
            return Err(ApiError::new(StatusCode::SERVICE_UNAVAILABLE, "overloaded"));
        }
        let b = buckets.entry(key).or_insert(Bucket {
            tokens: capacity as f64,
            last: now,
        });
        b.tokens = (b.tokens + now.duration_since(b.last).as_secs_f64() * capacity as f64 / period)
            .min(capacity as f64);
        b.last = now;
        if b.tokens < 1.0 {
            let mut e = ApiError::new(StatusCode::TOO_MANY_REQUESTS, "rate_limited");
            e.retry = Some(((1.0 - b.tokens) * period / capacity as f64).ceil() as u64);
            return Err(e);
        }
        b.tokens -= 1.0;
        Ok(())
    }
}
pub fn router(state: AppState) -> Router {
    Router::new().route("/health/live",get(||async{Json(json!({"status":"ok"}))}))
 .route("/health/ready",get(ready)).route("/v1/installations",post(register))
 .route("/v1/operations",post(operation)).route("/v1/snapshot",get(snapshot))
 .route("/v1/installations/current",delete(remove))
 .layer(DefaultBodyLimit::max(16*1024))
 .layer(axum::middleware::from_fn(|request:axum::extract::Request,next:axum::middleware::Next|async move{
  let started=Instant::now();let method=request.method().clone();let path=request.uri().path().to_owned();
  let request_id=uuid::Uuid::new_v4().to_string();let mut response=next.run(request).await;
  tracing::info!(%request_id,%method,%path,status=response.status().as_u16(),elapsed_ms=started.elapsed().as_millis(),"request");
  response.headers_mut().insert("x-request-id",request_id.parse().expect("uuid header"));response
 }))
 .with_state(state)
}
async fn ready(State(s): State<AppState>) -> Response {
    match sqlx::query("SELECT 1").execute(&s.pool).await {
        Ok(_) => Json(json!({"status":"ok"})).into_response(),
        Err(_) => (
            StatusCode::SERVICE_UNAVAILABLE,
            Json(json!({"status":"unavailable"})),
        )
            .into_response(),
    }
}
struct Credentials {
    id: String,
    hash: Vec<u8>,
}
fn credentials(id: &str, secret: &str) -> Result<Credentials> {
    domain::uuid(id).map_err(|_| ApiError::auth())?;
    let bytes = URL_SAFE_NO_PAD
        .decode(secret)
        .map_err(|_| ApiError::auth())?;
    if bytes.len() != 32 || URL_SAFE_NO_PAD.encode(&bytes) != secret {
        return Err(ApiError::auth());
    }
    Ok(Credentials {
        id: id.to_owned(),
        hash: Sha256::digest(bytes).to_vec(),
    })
}
fn bearer(headers: &HeaderMap) -> Result<Credentials> {
    let raw = headers
        .get("authorization")
        .and_then(|h| h.to_str().ok())
        .and_then(|s| s.strip_prefix("Bearer "))
        .ok_or_else(ApiError::auth)?;
    let (id, secret) = raw.split_once('.').ok_or_else(ApiError::auth)?;
    credentials(id, secret)
}
async fn authenticate(
    tx: &mut Transaction<'_, Sqlite>,
    c: &Credentials,
    allow_revoked: bool,
    allow_missing: bool,
) -> Result<Option<i64>> {
    let row =
        sqlx::query("SELECT secret_hash,last_seq,revoked_at_utc_ms FROM installations WHERE id=?")
            .bind(&c.id)
            .fetch_optional(&mut **tx)
            .await?;
    let Some(row) = row else {
        return if allow_missing {
            Ok(None)
        } else {
            Err(ApiError::auth())
        };
    };
    let stored: Vec<u8> = row.get("secret_hash");
    if !bool::from(stored.ct_eq(&c.hash)) {
        return Err(ApiError::auth());
    }
    if row.get::<Option<i64>, _>("revoked_at_utc_ms").is_some() && !allow_revoked {
        return Err(ApiError::new(StatusCode::GONE, "installation_revoked"));
    }
    Ok(Some(row.get("last_seq")))
}
async fn register(
    State(s): State<AppState>,
    peer: ConnectInfo<SocketAddr>,
    body: std::result::Result<Json<Value>, JsonRejection>,
) -> Result<Response> {
    let ip = peer.0.ip().to_string();
    s.limit(format!("register:{ip}"), s.limits.registrations, 3600.0)?;
    let p: Registration = domain::decode(parse_json(body)?)?;
    domain::uuid(&p.installation_id)?;
    let c = credentials(&p.installation_id, &p.secret)
        .map_err(|_| ApiError::invalid("invalid_secret"))?;
    let mut tx = s.pool.begin().await?;
    let existing = authenticate(&mut tx, &c, false, true).await?.is_some();
    if !existing {
        sqlx::query("INSERT INTO installations(id,secret_hash,created_at_utc_ms) VALUES(?,?,?)")
            .bind(&c.id)
            .bind(&c.hash)
            .bind(now())
            .execute(&mut *tx)
            .await?;
    }
    tx.commit().await?;
    Ok((
        if existing {
            StatusCode::OK
        } else {
            StatusCode::CREATED
        },
        Json(json!({"installation_id":c.id,"status":if existing{"existing"}else{"created"}})),
    )
        .into_response())
}
async fn operation(
    State(s): State<AppState>,
    headers: HeaderMap,
    body: std::result::Result<Json<Value>, JsonRejection>,
) -> Result<Json<Value>> {
    let c = bearer(&headers)?;
    let value = parse_json(body)?;
    // serde_json's Map is a BTreeMap: recursive keys are sorted, integer tokens stay integers.
    let hash =
        Sha256::digest(serde_json::to_vec(&value).map_err(|_| ApiError::invalid("invalid_json"))?)
            .to_vec();
    let (op, payload) = Operation::parse(value)?;
    let mut tx = s.pool.begin().await?;
    let last = authenticate(&mut tx, &c, false, false)
        .await?
        .ok_or_else(ApiError::auth)?;
    s.limit(
        format!("operation:{}", c.id),
        s.limits.burst,
        60.0 * s.limits.burst as f64 / s.limits.operations_per_minute as f64,
    )?;
    let receipt=sqlx::query("SELECT seq,op_id,request_hash,accepted_at_utc_ms FROM operation_receipts WHERE installation_id=? AND (seq=? OR op_id=?)").bind(&c.id).bind(op.seq).bind(&op.op_id).fetch_all(&mut *tx).await?;
    if !receipt.is_empty() {
        if receipt.len() == 1
            && receipt[0].get::<i64, _>("seq") == op.seq
            && receipt[0].get::<String, _>("op_id") == op.op_id
            && receipt[0].get::<Vec<u8>, _>("request_hash") == hash
        {
            let accepted: i64 = receipt[0].get("accepted_at_utc_ms");
            tx.commit().await?;
            return Ok(Json(
                json!({"op_id":op.op_id,"seq":op.seq,"status":"duplicate","accepted_at_utc_ms":accepted}),
            ));
        }
        return Err(ApiError::conflict("operation_mismatch"));
    }
    if op.seq != last + 1 {
        let mut e = ApiError::conflict("sequence_gap");
        e.expected = Some(last + 1);
        return Err(e);
    }
    payload.validate()?;
    apply(&mut tx, &c.id, &op, &payload).await?;
    let accepted = now();
    sqlx::query("INSERT INTO operation_receipts VALUES(?,?,?,?,?)")
        .bind(&c.id)
        .bind(op.seq)
        .bind(&op.op_id)
        .bind(hash)
        .bind(accepted)
        .execute(&mut *tx)
        .await?;
    sqlx::query("UPDATE installations SET last_seq=? WHERE id=?")
        .bind(op.seq)
        .bind(&c.id)
        .execute(&mut *tx)
        .await?;
    tx.commit().await?;
    Ok(Json(
        json!({"op_id":op.op_id,"seq":op.seq,"status":"applied","accepted_at_utc_ms":accepted}),
    ))
}
async fn apply(
    tx: &mut Transaction<'_, Sqlite>,
    installation: &str,
    op: &Operation,
    payload: &Payload,
) -> Result<()> {
    match payload {
        Payload::Project(p) => {
            let old = sqlx::query(
                "SELECT unit,created_at_utc_ms FROM projects WHERE installation_id=? AND id=?",
            )
            .bind(installation)
            .bind(&op.entity_id)
            .fetch_optional(&mut **tx)
            .await?;
            if let Some(old) = old {
                if old.get::<i64, _>("created_at_utc_ms") != p.created_at_utc_ms {
                    return Err(ApiError::invalid("created_at_immutable"));
                }
                if old.get::<String, _>("unit") != p.unit
                    && sqlx::query_scalar::<_, i64>(
                        "SELECT COUNT(*) FROM entries WHERE installation_id=? AND project_id=?",
                    )
                    .bind(installation)
                    .bind(&op.entity_id)
                    .fetch_one(&mut **tx)
                    .await?
                        > 0
                {
                    return Err(ApiError::invalid("unit_locked"));
                }
            } else if p.archived {
                return Err(ApiError::invalid("new_project_archived"));
            }
            sqlx::query("INSERT INTO projects VALUES(?,?,?,?,?,?,?,?,?) ON CONFLICT(installation_id,id) DO UPDATE SET name=excluded.name,unit=excluded.unit,icon_key=excluded.icon_key,quick_amount=excluded.quick_amount,archived=excluded.archived,updated_at_utc_ms=excluded.updated_at_utc_ms")
    .bind(installation).bind(&op.entity_id).bind(&p.name).bind(&p.unit).bind(&p.icon_key).bind(p.quick_amount).bind(p.archived).bind(p.created_at_utc_ms).bind(p.updated_at_utc_ms).execute(&mut **tx).await?;
        }
        Payload::Entry(e) => {
            if sqlx::query_scalar::<_, i64>(
                "SELECT COUNT(*) FROM entries WHERE installation_id=? AND id=?",
            )
            .bind(installation)
            .bind(&op.entity_id)
            .fetch_one(&mut **tx)
            .await?
                > 0
            {
                return Err(ApiError::conflict("entity_exists"));
            }
            let archived = sqlx::query_scalar::<_, bool>(
                "SELECT archived FROM projects WHERE installation_id=? AND id=?",
            )
            .bind(installation)
            .bind(&e.project_id)
            .fetch_optional(&mut **tx)
            .await?;
            if archived != Some(false) {
                return Err(ApiError::invalid("project_unavailable"));
            }
            sqlx::query("INSERT INTO entries VALUES(?,?,?,?,?,?,?,NULL)")
                .bind(installation)
                .bind(&op.entity_id)
                .bind(&e.project_id)
                .bind(e.amount)
                .bind(e.occurred_at_utc_ms)
                .bind(e.utc_offset_minutes)
                .bind(&e.local_date)
                .execute(&mut **tx)
                .await?;
        }
        Payload::Void(v) => {
            let result=sqlx::query("UPDATE entries SET voided_at_utc_ms=COALESCE(voided_at_utc_ms,?) WHERE installation_id=? AND id=?").bind(v.voided_at_utc_ms).bind(installation).bind(&op.entity_id).execute(&mut **tx).await?;
            if result.rows_affected() == 0 {
                return Err(ApiError::invalid("entry_unavailable"));
            }
        }
    };
    Ok(())
}
async fn snapshot(State(s): State<AppState>, headers: HeaderMap) -> Result<Json<Value>> {
    let c = bearer(&headers)?;
    let mut tx = s.pool.begin().await?;
    let last = authenticate(&mut tx, &c, false, false)
        .await?
        .ok_or_else(ApiError::auth)?;
    s.limit(format!("snapshot:{}", c.id), s.limits.snapshots, 60.0)?;
    // A bound prevents accidental unbounded allocation in this diagnostic endpoint.
    let count:i64=sqlx::query_scalar("SELECT (SELECT COUNT(*) FROM entries WHERE installation_id=?)+(SELECT COUNT(*) FROM projects WHERE installation_id=?)").bind(&c.id).bind(&c.id).fetch_one(&mut *tx).await?;
    if count > 100_000 {
        return Err(ApiError::new(
            StatusCode::SERVICE_UNAVAILABLE,
            "snapshot_too_large",
        ));
    }
    let projects=sqlx::query("SELECT * FROM projects WHERE installation_id=? ORDER BY id").bind(&c.id).fetch_all(&mut *tx).await?.iter().map(|r|json!({
  "id":r.get::<String,_>("id"),"name":r.get::<String,_>("name"),"unit":r.get::<String,_>("unit"),"icon_key":r.get::<String,_>("icon_key"),"quick_amount":r.get::<i64,_>("quick_amount"),"archived":r.get::<bool,_>("archived"),"created_at_utc_ms":r.get::<i64,_>("created_at_utc_ms"),"updated_at_utc_ms":r.get::<i64,_>("updated_at_utc_ms")
 })).collect::<Vec<_>>();
    let entries=sqlx::query("SELECT * FROM entries WHERE installation_id=? ORDER BY id").bind(&c.id).fetch_all(&mut *tx).await?.iter().map(|r|json!({
  "id":r.get::<String,_>("id"),"project_id":r.get::<String,_>("project_id"),"amount":r.get::<i64,_>("amount"),"occurred_at_utc_ms":r.get::<i64,_>("occurred_at_utc_ms"),"utc_offset_minutes":r.get::<i64,_>("utc_offset_minutes"),"local_date":r.get::<String,_>("local_date"),"voided_at_utc_ms":r.get::<Option<i64>,_>("voided_at_utc_ms")
 })).collect::<Vec<_>>();
    tx.commit().await?;
    Ok(Json(
        json!({"schema_version":1,"installation_id":c.id,"last_seq":last,"exported_at_utc_ms":now(),"projects":projects,"entries":entries}),
    ))
}
async fn remove(State(s): State<AppState>, headers: HeaderMap) -> Result<StatusCode> {
    let c = bearer(&headers)?;
    let mut tx = s.pool.begin().await?;
    if authenticate(&mut tx, &c, true, true).await?.is_some() {
        for table in ["entries", "projects", "operation_receipts"] {
            sqlx::query(&format!("DELETE FROM {table} WHERE installation_id=?"))
                .bind(&c.id)
                .execute(&mut *tx)
                .await?;
        }
        sqlx::query("UPDATE installations SET revoked_at_utc_ms=COALESCE(revoked_at_utc_ms,?),last_seq=0,created_at_utc_ms=0 WHERE id=?").bind(now()).bind(&c.id).execute(&mut *tx).await?;
    }
    tx.commit().await?;
    Ok(StatusCode::NO_CONTENT)
}
