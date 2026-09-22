use kodo_api::{AppState, Limits, router};
use std::{env, net::SocketAddr};
fn quota(name: &str, default: u32) -> u32 {
    env::var(name)
        .ok()
        .and_then(|v| v.parse().ok())
        .filter(|v| *v > 0)
        .unwrap_or(default)
}
#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "kodo_api=info".into()),
        )
        .init();
    let url = env::var("KODO_DATABASE_URL")
        .unwrap_or_else(|_| "sqlite://var/kodo/kodo.sqlite".to_owned());
    let bind = env::var("KODO_BIND").unwrap_or_else(|_| "127.0.0.1:8080".to_owned());
    let limits = Limits {
        registrations: quota("KODO_REGISTRATIONS_PER_HOUR", 10),
        operations_per_minute: quota("KODO_OPERATIONS_PER_MINUTE", 120),
        burst: quota("KODO_OPERATION_BURST", 60),
        snapshots: quota("KODO_SNAPSHOTS_PER_MINUTE", 6),
    };
    let state = AppState::connect(&url, limits).await?;
    let listener = tokio::net::TcpListener::bind(bind).await?;
    axum::serve(
        listener,
        router(state).into_make_service_with_connect_info::<SocketAddr>(),
    )
    .with_graceful_shutdown(async {
        let _ = tokio::signal::ctrl_c().await;
    })
    .await?;
    Ok(())
}
