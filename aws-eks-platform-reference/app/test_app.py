from app import app


def test_health_and_readiness_endpoints():
    client = app.test_client()

    health = client.get("/healthz")
    ready = client.get("/readyz")

    assert health.status_code == 200
    assert health.get_json() == {"status": "healthy"}
    assert ready.status_code == 200
    assert ready.get_json() == {"status": "ready"}


def test_metrics_include_request_counters():
    client = app.test_client()
    client.get("/")

    metrics = client.get("/metrics")
    body = metrics.get_data(as_text=True)

    assert metrics.status_code == 200
    assert "http_requests_total" in body
    assert "http_request_duration_seconds" in body


def test_synthetic_error_is_observable():
    client = app.test_client()
    response = client.get("/simulate-error")

    assert response.status_code == 500
