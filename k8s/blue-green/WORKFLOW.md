# Blue-Green Deployment Workflow

## Visual Workflow

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Blue-Green Deployment Workflow                   │
└─────────────────────────────────────────────────────────────────────┘

Phase 1: Initial State (Blue is Production)
┌──────────────────────────────────────────────────────────────┐
│                                                               │
│  Service (version: blue) ──────────────┐                    │
│                                         │                    │
│                                         ▼                    │
│                              ┌─────────────────┐            │
│                              │  Blue (v1.0.0)  │            │
│                              │  Status: ACTIVE │            │
│                              │  Traffic: 100%  │            │
│                              └─────────────────┘            │
│                                                               │
│                              ┌─────────────────┐            │
│                              │  Green          │            │
│                              │  Status: EMPTY  │            │
│                              │  Traffic: 0%    │            │
│                              └─────────────────┘            │
└──────────────────────────────────────────────────────────────┘

                            ⬇ Deploy New Version

Phase 2: Deploy to Green
┌──────────────────────────────────────────────────────────────┐
│                                                               │
│  Service (version: blue) ──────────────┐                    │
│                                         │                    │
│                                         ▼                    │
│                              ┌─────────────────┐            │
│                              │  Blue (v1.0.0)  │            │
│                              │  Status: ACTIVE │            │
│                              │  Traffic: 100%  │            │
│                              └─────────────────┘            │
│                                                               │
│                              ┌─────────────────┐            │
│                              │  Green (v2.0.0) │◄─── Deploy │
│                              │  Status: TESTING│            │
│                              │  Traffic: 0%    │            │
│                              └─────────────────┘            │
└──────────────────────────────────────────────────────────────┘

                            ⬇ Test Green Environment

Phase 3: Testing Green
┌──────────────────────────────────────────────────────────────┐
│                                                               │
│  Service (version: blue) ──────────────┐                    │
│                                         │                    │
│                                         ▼                    │
│                              ┌─────────────────┐            │
│                              │  Blue (v1.0.0)  │            │
│                              │  Status: ACTIVE │            │
│                              │  Traffic: 100%  │            │
│                              └─────────────────┘            │
│                                                               │
│                              ┌─────────────────┐            │
│  Port-forward for testing ──►│  Green (v2.0.0) │            │
│                              │  Status: READY  │            │
│                              │  Traffic: 0%    │            │
│                              └─────────────────┘            │
└──────────────────────────────────────────────────────────────┘

                            ⬇ Switch Traffic

Phase 4: Traffic Switch (Atomic)
┌──────────────────────────────────────────────────────────────┐
│                                                               │
│  Service (version: green) ─────────────┐                    │
│                                         │                    │
│                                         │                    │
│                              ┌─────────────────┐            │
│                              │  Blue (v1.0.0)  │            │
│                              │  Status: STANDBY│            │
│                              │  Traffic: 0%    │            │
│                              └─────────────────┘            │
│                                         ▲                    │
│                                         │                    │
│                              ┌─────────────────┐            │
│                              │  Green (v2.0.0) │            │
│                              │  Status: ACTIVE │            │
│                              │  Traffic: 100%  │◄─── Switch │
│                              └─────────────────┘            │
└──────────────────────────────────────────────────────────────┘

                            ⬇ Monitor & Validate

Phase 5: Monitoring
┌──────────────────────────────────────────────────────────────┐
│                                                               │
│  Service (version: green) ─────────────┐                    │
│                                         │                    │
│                                         │                    │
│                              ┌─────────────────┐            │
│                              │  Blue (v1.0.0)  │            │
│                              │  Status: STANDBY│            │
│                              │  Traffic: 0%    │            │
│                              └─────────────────┘            │
│                                         ▲                    │
│                                         │ Rollback if needed │
│                              ┌─────────────────┐            │
│  Monitor: Logs, Metrics  ───►│  Green (v2.0.0) │            │
│           Error Rates        │  Status: ACTIVE │            │
│           Response Times     │  Traffic: 100%  │            │
│                              └─────────────────┘            │
└──────────────────────────────────────────────────────────────┘

                            ⬇ If Stable

Phase 6: Cleanup
┌──────────────────────────────────────────────────────────────┐
│                                                               │
│  Service (version: green) ─────────────┐                    │
│                                         │                    │
│                                         │                    │
│                              ┌─────────────────┐            │
│                              │  Blue (v1.0.0)  │            │
│                              │  Status: SCALED │◄─── Scale  │
│                              │  Replicas: 0    │      Down  │
│                              └─────────────────┘            │
│                                                               │
│                              ┌─────────────────┐            │
│                              │  Green (v2.0.0) │            │
│                              │  Status: ACTIVE │            │
│                              │  Traffic: 100%  │            │
│                              └─────────────────┘            │
└──────────────────────────────────────────────────────────────┘

                            ⬇ Next Deployment

Phase 7: Ready for Next Deployment
┌──────────────────────────────────────────────────────────────┐
│                                                               │
│  Service (version: green) ─────────────┐                    │
│                                         │                    │
│                                         │                    │
│                              ┌─────────────────┐            │
│                              │  Blue           │◄─── Deploy │
│                              │  Status: EMPTY  │      v3.0.0│
│                              │  Traffic: 0%    │      Here  │
│                              └─────────────────┘            │
│                                         ▲                    │
│                                         │                    │
│                              ┌─────────────────┐            │
│                              │  Green (v2.0.0) │            │
│                              │  Status: ACTIVE │            │
│                              │  Traffic: 100%  │            │
│                              └─────────────────┘            │
└──────────────────────────────────────────────────────────────┘
```

## Rollback Workflow

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Rollback Workflow                            │
└─────────────────────────────────────────────────────────────────────┘

Issue Detected in Green
┌──────────────────────────────────────────────────────────────┐
│                                                               │
│  Service (version: green) ─────────────┐                    │
│                                         │                    │
│                                         │                    │
│                              ┌─────────────────┐            │
│                              │  Blue (v1.0.0)  │            │
│                              │  Status: STANDBY│            │
│                              │  Traffic: 0%    │            │
│                              └─────────────────┘            │
│                                         ▲                    │
│                                         │                    │
│                              ┌─────────────────┐            │
│                              │  Green (v2.0.0) │            │
│                              │  Status: ERROR! │◄─── Issue  │
│                              │  Traffic: 100%  │      Found │
│                              └─────────────────┘            │
└──────────────────────────────────────────────────────────────┘

                            ⬇ Execute Rollback

Rollback Executed (< 5 seconds)
┌──────────────────────────────────────────────────────────────┐
│                                                               │
│  Service (version: blue) ───────────────┐                   │
│                                         │                    │
│                                         ▼                    │
│                              ┌─────────────────┐            │
│                              │  Blue (v1.0.0)  │            │
│                              │  Status: ACTIVE │◄─── Switch │
│                              │  Traffic: 100%  │      Back  │
│                              └─────────────────┘            │
│                                                               │
│                              ┌─────────────────┐            │
│                              │  Green (v2.0.0) │            │
│                              │  Status: FAILED │            │
│                              │  Traffic: 0%    │            │
│                              └─────────────────┘            │
└──────────────────────────────────────────────────────────────┘

                            ⬇ Investigate & Fix

Production Stable, Investigate Issue
┌──────────────────────────────────────────────────────────────┐
│                                                               │
│  Service (version: blue) ───────────────┐                   │
│                                         │                    │
│                                         ▼                    │
│                              ┌─────────────────┐            │
│                              │  Blue (v1.0.0)  │            │
│                              │  Status: ACTIVE │            │
│                              │  Traffic: 100%  │            │
│                              └─────────────────┘            │
│                                                               │
│                              ┌─────────────────┐            │
│  Analyze logs & fix issue ──►│  Green (v2.0.0) │            │
│                              │  Status: DEBUG  │            │
│                              │  Traffic: 0%    │            │
│                              └─────────────────┘            │
└──────────────────────────────────────────────────────────────┘
```

## Command Timeline

```
Time    Command                                 State
────────────────────────────────────────────────────────────────
T+0     ./deploy-blue-green.sh blue v1.0.0     Blue deployed
T+1     kubectl apply -f *-service-*.yaml       Services created
T+2     # Production running on blue            Blue: 100%

        ─── New Version Ready ───

T+10    ./deploy-blue-green.sh green v2.0.0    Green deploying
T+11    # Wait for pods ready                   Green: 0%
T+12    kubectl port-forward ...                Testing green
T+13    # Run tests on green                    Testing...
T+14    # Tests pass                            Ready to switch

        ─── Traffic Switch ───

T+15    ./switch-traffic.sh green              Switching...
T+15.5  # Traffic switched                      Green: 100%
T+16    # Monitor logs                          Monitoring...
T+20    # All metrics good                      Stable

        ─── Cleanup ───

T+30    kubectl scale ... --replicas=0         Blue scaled down
T+31    # Deployment complete                   Green: 100%

        ─── If Rollback Needed ───

T+15    ./switch-traffic.sh green              Switching...
T+16    # Issue detected!                       Error!
T+16.5  ./rollback.sh blue                     Rolling back...
T+17    # Traffic back on blue                  Blue: 100%
T+18    # Production stable                     Investigating...
```

## Decision Tree

```
                    Start Deployment
                          │
                          ▼
                  Build New Version
                          │
                          ▼
              Deploy to Green Environment
                          │
                          ▼
                  Wait for Pods Ready
                          │
                          ▼
                  Test Green Environment
                          │
                ┌─────────┴─────────┐
                │                   │
            Tests Pass          Tests Fail
                │                   │
                ▼                   ▼
        Switch Traffic         Fix Issues
        to Green               Redeploy
                │                   │
                ▼                   │
        Monitor Production          │
                │                   │
        ┌───────┴───────┐          │
        │               │           │
    All Good      Issues Found     │
        │               │           │
        ▼               ▼           │
    Cleanup         Rollback        │
    Old Version     to Blue         │
        │               │           │
        ▼               ▼           │
    Complete    Investigate ────────┘
                & Fix
```

## State Transitions

```
Blue State Machine:
EMPTY → DEPLOYING → READY → ACTIVE → STANDBY → SCALED_DOWN → EMPTY

Green State Machine:
EMPTY → DEPLOYING → READY → TESTING → ACTIVE → STANDBY → SCALED_DOWN → EMPTY

Service State Machine:
BLUE → SWITCHING → GREEN → SWITCHING → BLUE
```

## Timing Expectations

| Phase | Duration | Notes |
|-------|----------|-------|
| Build Images | 2-5 min | Depends on image size |
| Deploy to Green | 2-3 min | Includes pod startup |
| Testing | 5-15 min | Manual testing time |
| Traffic Switch | < 1 sec | Atomic operation |
| Monitoring | 30+ min | Before cleanup |
| Rollback | < 5 sec | If needed |
| Cleanup | 1 min | Scale down old version |

## Best Practices Timeline

```
Day 1: Initial Setup
├── Deploy blue environment
├── Verify production traffic
└── Document baseline metrics

Day 2-N: Normal Operations
├── Blue serves production
└── Monitor metrics

Deployment Day:
├── T-60min: Build and test new version locally
├── T-30min: Deploy to green environment
├── T-15min: Test green thoroughly
├── T-0min:  Switch traffic to green
├── T+30min: Monitor closely
├── T+60min: Verify all metrics
├── T+2hr:   Scale down blue (if stable)
└── T+24hr:  Post-deployment review
```
