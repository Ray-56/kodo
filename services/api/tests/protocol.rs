use axum::{
    Extension, Router,
    body::Body,
    extract::ConnectInfo,
    http::{Request, StatusCode},
};
use base64::{Engine, engine::general_purpose::URL_SAFE_NO_PAD};
use http_body_util::BodyExt;
use kodo_api::{AppState, Limits, router};
use serde_json::{Value, json};
use std::net::SocketAddr;
use tower::ServiceExt;
struct Harness {
    app: Router,
    state: AppState,
    _dir: tempfile::TempDir,
    id: String,
    secret: String,
}
impl Harness {
    async fn new() -> Self {
        let dir = tempfile::tempdir().unwrap();
        let url = format!("sqlite://{}", dir.path().join("test.sqlite").display());
        let state = AppState::connect(
            &url,
            Limits {
                registrations: 1000,
                operations_per_minute: 10000,
                burst: 10000,
                snapshots: 10000,
            },
        )
        .await
        .unwrap();
        let app = router(state.clone()).layer(Extension(ConnectInfo(
            "127.0.0.1:3210".parse::<SocketAddr>().unwrap(),
        )));
        let h = Self {
            app,
            state,
            _dir: dir,
            id: uuid::Uuid::new_v4().to_string(),
            secret: URL_SAFE_NO_PAD.encode([19u8; 32]),
        };
        assert_eq!(
            h.request(
                "POST",
                "/v1/installations",
                Some(json!({"installation_id":h.id,"secret":h.secret})),
                false
            )
            .await
            .0,
            201
        );
        h
    }
    async fn request(
        &self,
        method: &str,
        path: &str,
        body: Option<Value>,
        auth: bool,
    ) -> (u16, Value) {
        self.raw(
            method,
            path,
            body.map(|v| v.to_string()).unwrap_or_default(),
            auth,
        )
        .await
    }
    async fn raw(&self, method: &str, path: &str, body: String, auth: bool) -> (u16, Value) {
        let mut b = Request::builder()
            .method(method)
            .uri(path)
            .header("content-type", "application/json");
        if auth {
            b = b.header(
                "authorization",
                format!("Bearer {}.{}", self.id, self.secret),
            );
        }
        let response = self
            .app
            .clone()
            .oneshot(b.body(Body::from(body)).unwrap())
            .await
            .unwrap();
        let status = response.status().as_u16();
        let bytes = response.into_body().collect().await.unwrap().to_bytes();
        (
            status,
            serde_json::from_slice(&bytes).unwrap_or(Value::Null),
        )
    }
    async fn op(&self, body: Value) -> (u16, Value) {
        self.request("POST", "/v1/operations", Some(body), true)
            .await
    }
    async fn snapshot(&self) -> Value {
        let (s, v) = self.request("GET", "/v1/snapshot", None, true).await;
        assert_eq!(s, 200);
        v
    }
}
fn op(seq: i64, kind: &str, id: &str, p: Value) -> Value {
    json!({"seq":seq,"op_id":uuid::Uuid::new_v4().to_string(),"kind":kind,"entity_id":id,"payload":p})
}
fn project() -> Value {
    json!({"name":"俯卧撑","unit":"个","icon_key":"dumbbell","quick_amount":10,"archived":false,"created_at_utc_ms":1789106400000i64,"updated_at_utc_ms":1789106400000i64})
}
fn entry(p: &str) -> Value {
    json!({"project_id":p,"amount":10,"occurred_at_utc_ms":1789106400000i64,"utc_offset_minutes":480,"local_date":"2026-09-11"})
}
#[tokio::test]
async fn registration_auth_isolation_and_revoke() {
    let h = Harness::new().await;
    assert_eq!(
        h.request(
            "POST",
            "/v1/installations",
            Some(json!({"installation_id":h.id,"secret":h.secret})),
            false
        )
        .await
        .0,
        200
    );
    assert_eq!(
        h.request(
            "POST",
            "/v1/installations",
            Some(json!({"installation_id":h.id,"secret":URL_SAFE_NO_PAD.encode([20u8;32])})),
            false
        )
        .await
        .0,
        401
    );
    assert_eq!(h.request("GET", "/v1/snapshot", None, false).await.0, 401);
    let p = uuid::Uuid::new_v4().to_string();
    h.op(op(1, "project.put", &p, project())).await;
    let other = uuid::Uuid::new_v4().to_string();
    h.request(
        "POST",
        "/v1/installations",
        Some(json!({"installation_id":other,"secret":h.secret})),
        false,
    )
    .await;
    let request = Request::builder()
        .method("POST")
        .uri("/v1/operations")
        .header("content-type", "application/json")
        .header("authorization", format!("Bearer {}.{}", other, h.secret))
        .body(Body::from(
            op(1, "entry.add", &uuid::Uuid::new_v4().to_string(), entry(&p)).to_string(),
        ))
        .unwrap();
    assert_eq!(
        h.app.clone().oneshot(request).await.unwrap().status(),
        StatusCode::UNPROCESSABLE_ENTITY
    );
    for _ in 0..2 {
        assert_eq!(
            h.request("DELETE", "/v1/installations/current", None, true)
                .await
                .0,
            204
        );
    }
    assert_eq!(h.op(op(2, "project.put", &p, project())).await.0, 410);
    assert_eq!(
        h.request(
            "POST",
            "/v1/installations",
            Some(json!({"installation_id":h.id,"secret":h.secret})),
            false
        )
        .await
        .0,
        410
    );
    let n: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM projects")
        .fetch_one(&h.state.pool)
        .await
        .unwrap();
    assert_eq!(n, 0);
}
#[tokio::test]
async fn sequence_replay_mismatch_and_duplicate_before_archive_validation() {
    let h = Harness::new().await;
    let p = uuid::Uuid::new_v4().to_string();
    assert_eq!(h.op(op(1, "project.put", &p, project())).await.0, 200);
    let add = op(2, "entry.add", &uuid::Uuid::new_v4().to_string(), entry(&p));
    let original = h.op(add.clone()).await.1;
    for _ in 0..10 {
        let (s, r) = h.op(add.clone()).await;
        assert_eq!(s, 200);
        assert_eq!(r["status"], "duplicate");
        assert_eq!(r["accepted_at_utc_ms"], original["accepted_at_utc_ms"]);
    }
    let mut changed = add.clone();
    changed["payload"]["amount"] = json!(11);
    assert_eq!(h.op(changed).await.1["error"]["code"], "operation_mismatch");
    let mut reused = add.clone();
    reused["seq"] = json!(3);
    assert_eq!(h.op(reused).await.0, 409);
    let gap = h.op(op(4, "project.put", &p, project())).await;
    assert_eq!(gap.1["error"]["expected_seq"], 3);
    let mut archived = project();
    archived["archived"] = json!(true);
    assert_eq!(h.op(op(3, "project.put", &p, archived)).await.0, 200);
    assert_eq!(h.op(add.clone()).await.1["status"], "duplicate");
    assert_eq!(
        h.op(op(
            4,
            "entry.add",
            &uuid::Uuid::new_v4().to_string(),
            entry(&p)
        ))
        .await
        .0,
        422
    );
    let v = op(
        4,
        "entry.void",
        add["entity_id"].as_str().unwrap(),
        json!({"voided_at_utc_ms":1789106400001i64}),
    );
    assert_eq!(h.op(v).await.0, 200);
    assert_eq!(
        h.op(op(
            5,
            "entry.void",
            add["entity_id"].as_str().unwrap(),
            json!({"voided_at_utc_ms":1789106400002i64})
        ))
        .await
        .0,
        200
    );
    let s = h.snapshot().await;
    assert_eq!(s["entries"].as_array().unwrap().len(), 1);
    assert_eq!(s["last_seq"], 5);
    assert_eq!(s["entries"][0]["voided_at_utc_ms"], 1789106400001i64);
    let mut unit = project();
    unit["unit"] = json!("次");
    assert_eq!(h.op(op(6, "project.put", &p, unit)).await.0, 422);
}
#[tokio::test]
async fn strict_types_unknown_fields_body_size_dates_and_atomic_failures() {
    let h = Harness::new().await;
    let p = uuid::Uuid::new_v4().to_string();
    h.op(op(1, "project.put", &p, project())).await;
    for amount in [
        json!(0),
        json!(-1),
        json!(1.0),
        json!("1"),
        json!(true),
        json!(1000000),
    ] {
        let mut e = entry(&p);
        e["amount"] = amount;
        assert_eq!(
            h.op(op(2, "entry.add", &uuid::Uuid::new_v4().to_string(), e))
                .await
                .0,
            422
        );
    }
    let raw = op(2, "entry.add", &uuid::Uuid::new_v4().to_string(), entry(&p))
        .to_string()
        .replace("\"amount\":10", "\"amount\":1e1");
    assert_eq!(h.raw("POST", "/v1/operations", raw, true).await.0, 422);
    let mut bad = op(2, "entry.add", &uuid::Uuid::new_v4().to_string(), entry(&p));
    bad["installation_id"] = json!(h.id);
    assert_eq!(h.op(bad).await.0, 422);
    let mut bad = entry(&p);
    bad["local_date"] = json!("2000-01-01");
    assert_eq!(
        h.op(op(2, "entry.add", &uuid::Uuid::new_v4().to_string(), bad))
            .await
            .0,
        422
    );
    assert_eq!(
        h.raw("POST", "/v1/operations", "x".repeat(17000), true)
            .await
            .0,
        413
    );
    assert_eq!(h.snapshot().await["last_seq"], 1);
    sqlx::query("CREATE TRIGGER fail_receipt BEFORE INSERT ON operation_receipts BEGIN SELECT RAISE(ABORT,'test_failure'); END;").execute(&h.state.pool).await.unwrap();
    assert_eq!(
        h.op(op(
            2,
            "entry.add",
            &uuid::Uuid::new_v4().to_string(),
            entry(&p)
        ))
        .await
        .0,
        503
    );
    let s = h.snapshot().await;
    assert_eq!(s["entries"].as_array().unwrap().len(), 0);
    assert_eq!(s["last_seq"], 1);
}
#[tokio::test]
async fn canonical_order_and_file_reopen_are_durable() {
    let h = Harness::new().await;
    let p = uuid::Uuid::new_v4().to_string();
    let o = op(1, "project.put", &p, project());
    assert_eq!(h.op(o.clone()).await.0, 200);
    let pretty = serde_json::to_string_pretty(&o).unwrap();
    assert_eq!(
        h.raw("POST", "/v1/operations", pretty, true).await.1["status"],
        "duplicate"
    );
    h.state.pool.close().await;
    let url = format!("sqlite://{}", h._dir.path().join("test.sqlite").display());
    let reopened = AppState::connect(&url, Limits::default()).await.unwrap();
    let n: i64 = sqlx::query_scalar("SELECT last_seq FROM installations WHERE id=?")
        .bind(&h.id)
        .fetch_one(&reopened.pool)
        .await
        .unwrap();
    assert_eq!(n, 1);
    let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM operation_receipts")
        .fetch_one(&reopened.pool)
        .await
        .unwrap();
    assert_eq!(count, 1);
}
#[tokio::test]
async fn concurrent_delete_snapshot_operation_never_resurrects() {
    let h = Harness::new().await;
    let p = uuid::Uuid::new_v4().to_string();
    h.op(op(1, "project.put", &p, project())).await;
    let (add, snap, del) = tokio::join!(
        h.op(op(
            2,
            "entry.add",
            &uuid::Uuid::new_v4().to_string(),
            entry(&p)
        )),
        h.request("GET", "/v1/snapshot", None, true),
        h.request("DELETE", "/v1/installations/current", None, true)
    );
    assert!([200, 410].contains(&add.0));
    assert_eq!(del.0, 204);
    if snap.0 == 200 {
        let count = snap.1["entries"].as_array().unwrap().len();
        assert_eq!(snap.1["last_seq"], 1 + count as i64);
    } else {
        assert_eq!(snap.0, 410);
    }
    assert_eq!(h.request("GET", "/v1/snapshot", None, true).await.0, 410);
}
#[tokio::test]
async fn rate_limits_return_retry_after() {
    let dir = tempfile::tempdir().unwrap();
    let s = AppState::connect(
        &format!("sqlite://{}", dir.path().join("limit.sqlite").display()),
        Limits {
            registrations: 1,
            ..Limits::default()
        },
    )
    .await
    .unwrap();
    let app = router(s).layer(Extension(ConnectInfo(
        "127.0.0.1:32".parse::<SocketAddr>().unwrap(),
    )));
    for i in 0..2 {
        let req=Request::builder().method("POST").uri("/v1/installations").header("content-type","application/json").body(Body::from(json!({"installation_id":uuid::Uuid::new_v4().to_string(),"secret":URL_SAFE_NO_PAD.encode([1u8;32])}).to_string())).unwrap();
        let result = app.clone().oneshot(req).await.unwrap();
        if i == 0 {
            assert_eq!(result.status(), StatusCode::CREATED);
        } else {
            assert_eq!(result.status(), StatusCode::TOO_MANY_REQUESTS);
            assert!(result.headers().contains_key("retry-after"));
        }
    }
}

#[tokio::test]
async fn external_sqlite_write_lock_returns_503_without_partial_commit() {
    use sqlx::{Connection, Executor};
    let h = Harness::new().await;
    let p = uuid::Uuid::new_v4().to_string();
    assert_eq!(h.op(op(1, "project.put", &p, project())).await.0, 200);
    let url = format!("sqlite://{}", h._dir.path().join("test.sqlite").display());
    let mut other = sqlx::SqliteConnection::connect(&url).await.unwrap();
    other.execute("BEGIN IMMEDIATE").await.unwrap();
    let result = h
        .op(op(
            2,
            "entry.add",
            &uuid::Uuid::new_v4().to_string(),
            entry(&p),
        ))
        .await;
    assert_eq!(result.0, 503);
    other.execute("ROLLBACK").await.unwrap();
    let snapshot = h.snapshot().await;
    assert_eq!(snapshot["last_seq"], 1);
    assert!(snapshot["entries"].as_array().unwrap().is_empty());
}
