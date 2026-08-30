from time import perf_counter

from flask import Flask, Response, g, jsonify, request
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

app = Flask(__name__)

REQUESTS = Counter(
    "http_requests_total",
    "Total HTTP requests processed by the application.",
    ["method", "route", "status"],
)
REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency in seconds.",
    ["method", "route"],
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5),
)


@app.before_request
def start_timer() -> None:
    g.request_started_at = perf_counter()


@app.after_request
def record_request_metrics(response: Response) -> Response:
    route = request.url_rule.rule if request.url_rule else "unmatched"
    if route != "/metrics":
        REQUESTS.labels(request.method, route, str(response.status_code)).inc()
        REQUEST_LATENCY.labels(request.method, route).observe(
            perf_counter() - g.request_started_at
        )
    return response


@app.get("/")
def index():
    return jsonify(
        service="platform-demo",
        status="ok",
        message="Production-style EKS portfolio workload",
    )


@app.get("/healthz")
def health():
    return jsonify(status="healthy")


@app.get("/readyz")
def ready():
    return jsonify(status="ready")


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


@app.get("/simulate-error")
def simulate_error():
    return jsonify(error="synthetic failure for local observability testing"), 500
