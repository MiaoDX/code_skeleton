---
name: visual-harness
description: Run the visual harness (G1 or Realman) and programmatically diagnose grasp pipeline issues. Use whenever the user asks to check, run, or validate the grasp pipeline, visual harness, or grasp quality for any robot. Also trigger after code changes to the grasp controller, planner, WBC policy, or visual harness code — don't just eyeball the images.
---

# Visual Harness Check

Run the visual harness for the specified robot (G1 or Realman), then programmatically analyze the results. Never rely solely on visual inspection of snapshot images — always check the numeric data first and flag issues with evidence.

## Why This Exists

LLM visual inspection has confirmed bias: after implementing a fix, there's a tendency to interpret ambiguous images as "looks fine." This skill enforces a structured, numeric-first diagnostic that catches issues the images alone cannot reliably surface.

## Step 1: Run the Harness

Determine which robot from context (default: G1). Arguments are passed through (e.g., `--xyz`, `--case-id`, `--suite`).

**G1:**
```bash
rm -rf vis/g1_phase_capture/X35_Y20_Z10/
source .venv/bin/activate && python -m tests.visual_harness.g1_runner --allow-fail-verdict
```

**Realman** (if user specifies or context is Realman work):
```bash
rm -rf vis/realman_phase_capture/
source .venv/bin/activate && python -m tests.visual_harness.realman_runner --allow-fail-verdict
```

If it crashes, report the traceback and stop.

## Step 2: Load the Report

Find the output directory from the runner's stdout (`output_dir=...` line).
Read `<output_dir>/autonomous_report.json` and `<output_dir>/snapshot_bundle.json`.

Extract:
- `verdict`, `verdict_reasons`, `failure_taxonomy`
- `summary_metrics` (all numeric values)
- `thresholds` (pass/fail boundaries)
- `snapshot_order` (list of captured stages)
- Per-snapshot `q` arrays from `snapshot_bundle.json`

## Step 3: Run Programmatic Checks

Run ALL of the following checks. Report each as PASS/FAIL with numeric evidence.

### Check 1: Snapshot Completeness
Expected 13 snapshots for a full grasp+place cycle:
```
00_planned, 01_retract_done, 02_waist_rotate_done, 03_reik_checkpoint_done,
04_pregrasp_done, 05_approach_done, 06_close_done, 07_lift_done, 08_holding,
09_home_pre_place_done, 10_place_plan, 11_place_done, 12_home_final_done
```
FAIL if any are missing (indicates stage didn't fire or harness crashed mid-run).

### Check 2: Grasp Geometry
From `summary_metrics`, check each against `thresholds`:
- `grip_center_error_mm` (threshold: 50mm)
- `pinch_gap_error_mm` (threshold: 15mm)
- `index_middle_vertical_deg` (threshold: 20deg)
- `pinch_elevation_deg` (threshold: 15deg)

### Check 3: Waist Settling
- `waist_final_error_deg` should be < 5deg
- Check `failure_taxonomy` for `waist_settling_timeout` — should NOT be present
- Check runtime `last_waist_settle_timed_out` — should be false

### Check 4: Right Arm Drift (Command Level)
From `snapshot_bundle.json`, extract right arm joint indices (indices 17-23 in full robot q) from each snapshot's `q` array. Compare against the `00_planned` snapshot values.

```python
# Pseudo-check: right arm joints should not drift more than 5 degrees
for snapshot in snapshots:
    right_arm_q = snapshot.q[17:24]  # 7 right arm DOFs
    initial_right_arm = snapshots[0].q[17:24]
    max_delta_deg = max(abs(right_arm_q - initial_right_arm)) * 180/pi
    if max_delta_deg > 5.0:
        FAIL(f"{snapshot.name}: right arm drift {max_delta_deg:.1f} deg")
```

Note: these are MuJoCo ACTUAL positions (PD tracking), not commanded. Some drift from PD dynamics is expected. Threshold: 5 deg per joint.

### Check 5: Wrist-to-Bottle Distance Progression
From snapshot metrics, track `grip_center_error_mm` across stages. It should decrease from pregrasp through approach to close:
- `pregrasp_done` > `approach_done` > `close_done` (decreasing distance)
If close_done has HIGHER error than approach_done, the approach is diverging.

### Check 6: Standing Posture
- `pelvis_roll_deg` should be < 60 deg
- `pelvis_pitch_deg` should be < 60 deg
- `pelvis_height_m` should be within 0.15m of nominal (~0.75m)

### Check 7: Execution State
- If `execution_failure: IDLE` in failure_taxonomy AND the full place cycle completed (12_home_final_done exists), this is EXPECTED (not a real failure). Note it as "benign — full cycle completed."
- If `execution_failure` with abort reason, this IS a real failure.

## Step 4: Visual Spot-Check (After Numeric Checks)

Only AFTER completing all numeric checks, view these specific images and compare:
1. `00_planned_front2back.png` vs `06_close_done_front2back.png` — right arm position change
2. `04_pregrasp_done_top2down.png` — are waypoint markers near the wrist or disconnected?
3. `11_place_done_front2back.png` — is the robot upright or leaning/flipped?

Be SPECIFIC about what you see. Don't say "looks fine." Say "right arm shoulder angle changed approximately X degrees" or "waypoint markers start ~3cm from wrist tip in top-down view."

## Step 5: Report

Output a structured diagnostic:

```
## G1 Harness Diagnostic

**Verdict**: PASS / FAIL
**Snapshot count**: N/13

### Numeric Checks
| Check | Status | Value | Threshold | Notes |
|-------|--------|-------|-----------|-------|
| grip_center_error | PASS/FAIL | Xmm | 50mm | |
| pinch_gap | PASS/FAIL | Xmm | 15mm | |
| ... | | | | |

### Issues Found
1. [severity] description with numeric evidence
2. ...

### Visual Observations
1. Right arm: [specific observation with estimated angles]
2. Waypoints: [specific observation about marker-wrist alignment]
3. Place pose: [specific observation about body orientation]
```

## Adding New Checks

When the user reports a visual issue that this skill didn't catch:
1. Understand the root cause numerically (what metric would have caught it?)
2. Add a new check to this skill under "Step 3"
3. Set an appropriate threshold
4. This skill should grow over time to catch everything the user has historically flagged
