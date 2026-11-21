# MELSAVA — Host Reputation & Trust Scoring Rules

## Core Principle: Merit & Safety Over Popularity

MELSAVA prevents social monopolies and cold-start bias. Established hosts do not push out new creators, and new creators are never penalized for not having a long history.

---

## 1. Reputation Levels

```
                     [New Member]
                          │
                          ▼
                     [New Host] ─── (0-1 Completed Circles)
                          │         Initial capacity: 10
                          │         Rating: "Not yet rated"
                          ▼
                    [Active Host] ─── (>= 2 Completed Circles, >= 3 Reviews)
                          │           Initial capacity: 16
                          ▼
                   [Reliable Host] ─── (>= 5 Completed Circles, >= 5 Reviews, >= 4.2 Rating)
                          │           Initial capacity: 24
                          ▼
                   [Trusted Host] ─── (>= 10 Completed Circles, >= 10 Reviews, >= 4.7 Rating, >= 90% Attendance)
                                      Initial capacity: 30
                                      Priority Verified badge
```

---

## 2. Threshold for Average Ratings

- **Fewer than 5 Reviews**:
  - The UI displays **"Not yet rated"** and **"No completed circles yet"**.
  - **Zero stars (0.0 ★) are NEVER shown** for unrated or new hosts.
  - Review count is displayed as `(N reviews)` without an average number.
- **5 or More Reviews**:
  - The true arithmetic mean is calculated: `average_rating = SUM(rating) / COUNT(rating)`.
  - Displayed to 1 decimal place with a golden star (`4.9 ★`).

---

## 3. Cold-Start Discovery Weighting

In `SupabaseExperiencesRepository.applyFiltersAndRanking`:
- **New Host Boost**: Activities organized by hosts with `reputation_level = 'new_host'` or `is_new_host = true` receive a **+40 points bonus**.
- **Area Match**: If the user's selected neighborhood matches the activity area, a **+30 points bonus** is added.
- **City Match**: An activity in the user's city receives a **+20 points bonus**.
- **Timing Proximity**: Activities starting in 24–72 hours receive a **+15 points bonus**.

---

## 4. Attendance Reliability Metric

$$\text{Hosting Attendance Rate} = \frac{\text{Completed Hosted Meetups}}{\text{Completed Hosted Meetups} + \text{Host Cancellations}} \times 100\%$$

If a host cancels an activity with confirmed attendees within 24 hours of start time:
- It counts as an unexcused cancellation.
- If the attendance rate drops below 70%, the host is temporarily restricted to 1 active upcoming circle.

---

## 5. Review Integrity Protocol

1. **Attendee Verification**:
   - Only users who actively joined and had their attendance confirmed (`status = 'attended'`) by the host or moderator can submit a review.
2. **Self-Review Prevention**:
   - A host cannot review their own activity (`reviewer_id != host_id`).
3. **Single Review Constraint**:
   - A database unique constraint `UNIQUE (experience_id, reviewer_id)` guarantees each participant reviews an experience at most once.
4. **Structured Assessment**:
   - Rather than arbitrary text alone, attendees answer 5 binary quality & safety questions:
     1. Was the circle as described?
     2. Was the host welcoming and respectful?
     3. Did the host arrive on time?
     4. Did you feel safe and comfortable?
     5. Would you join another circle with this host?
