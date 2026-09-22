use crate::{ApiError, Result};
use serde::{Deserialize, Serialize};
use serde_json::Value;

pub const MAX_TIME: i64 = 4_102_444_799_999;
pub const MAX_SEQ: i64 = 9_007_199_254_740_991;
#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Registration {
    pub installation_id: String,
    pub secret: String,
}
#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Operation {
    pub op_id: String,
    pub seq: i64,
    pub kind: String,
    pub entity_id: String,
    pub payload: Value,
}
#[derive(Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct ProjectPayload {
    pub name: String,
    pub unit: String,
    pub icon_key: String,
    pub quick_amount: i64,
    pub archived: bool,
    pub created_at_utc_ms: i64,
    pub updated_at_utc_ms: i64,
}
#[derive(Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct EntryPayload {
    pub project_id: String,
    pub amount: i64,
    pub occurred_at_utc_ms: i64,
    pub utc_offset_minutes: i64,
    pub local_date: String,
}
#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
pub struct VoidPayload {
    pub voided_at_utc_ms: i64,
}
pub enum Payload {
    Project(ProjectPayload),
    Entry(EntryPayload),
    Void(VoidPayload),
}
pub fn decode<T: serde::de::DeserializeOwned>(value: Value) -> Result<T> {
    serde_json::from_value(value).map_err(|_| ApiError::invalid("invalid_fields"))
}
pub fn uuid(value: &str) -> Result<()> {
    if uuid::Uuid::parse_str(value).is_ok_and(|u| u.hyphenated().to_string() == value) {
        Ok(())
    } else {
        Err(ApiError::invalid("invalid_uuid"))
    }
}
pub fn timestamp(t: i64) -> Result<()> {
    if (0..=MAX_TIME).contains(&t) {
        Ok(())
    } else {
        Err(ApiError::invalid("invalid_timestamp"))
    }
}
fn text(s: &str, max: usize) -> Result<()> {
    if s.trim() != s
        || s.is_empty()
        || s.chars().count() > max
        || s.chars()
            .any(|c| c.is_control() || c == '\u{2028}' || c == '\u{2029}')
    {
        Err(ApiError::invalid("invalid_text"))
    } else {
        Ok(())
    }
}
impl Operation {
    pub fn parse(value: Value) -> Result<(Self, Payload)> {
        let op: Self = decode(value)?;
        uuid(&op.op_id)?;
        uuid(&op.entity_id)?;
        if !(1..=MAX_SEQ).contains(&op.seq) {
            return Err(ApiError::invalid("invalid_seq"));
        }
        let p = match op.kind.as_str() {
            "project.put" => Payload::Project(decode(op.payload.clone())?),
            "entry.add" => Payload::Entry(decode(op.payload.clone())?),
            "entry.void" => Payload::Void(decode(op.payload.clone())?),
            _ => return Err(ApiError::invalid("unknown_operation")),
        };
        Ok((op, p))
    }
}
impl Payload {
    pub fn validate(&self) -> Result<()> {
        match self {
            Self::Project(p) => {
                text(&p.name, 40)?;
                text(&p.unit, 8)?;
                timestamp(p.created_at_utc_ms)?;
                timestamp(p.updated_at_utc_ms)?;
                if !(1..=9999).contains(&p.quick_amount)
                    || !["dumbbell", "book", "leaf", "code", "droplet", "check"]
                        .contains(&p.icon_key.as_str())
                {
                    return Err(ApiError::invalid("invalid_project"));
                }
            }
            Self::Entry(e) => {
                uuid(&e.project_id)?;
                timestamp(e.occurred_at_utc_ms)?;
                if !(1..=999999).contains(&e.amount)
                    || !(-840..=840).contains(&e.utc_offset_minutes)
                {
                    return Err(ApiError::invalid("invalid_entry"));
                }
                let local = chrono::DateTime::from_timestamp_millis(
                    e.occurred_at_utc_ms + e.utc_offset_minutes * 60_000,
                )
                .ok_or_else(|| ApiError::invalid("invalid_timestamp"))?;
                if local.format("%Y-%m-%d").to_string() != e.local_date {
                    return Err(ApiError::invalid("date_mismatch"));
                }
            }
            Self::Void(v) => timestamp(v.voided_at_utc_ms)?,
        };
        Ok(())
    }
}
