-- Read-side queries, local Drift version; server equivalent also filters installation_id.
-- Binding :today is the current device calendar date, not server UTC date.
SELECT p.id, p.name, p.unit,
 COALESCE(SUM(CASE WHEN e.voided_at_utc_ms IS NULL AND e.local_date=:today THEN e.amount ELSE 0 END),0) AS today_amount,
 COALESCE(SUM(CASE WHEN e.voided_at_utc_ms IS NULL THEN e.amount ELSE 0 END),0) AS total_amount
FROM projects p LEFT JOIN entries e ON e.project_id=p.id
WHERE p.archived=0 GROUP BY p.id ORDER BY p.created_at_utc_ms DESC,p.id DESC;
-- Overall analytics measures number of valid logging events, NEVER sum of mixed units.
SELECT local_date, COUNT(*) AS entry_count FROM entries
WHERE voided_at_utc_ms IS NULL AND local_date BETWEEN :from_date AND :to_date
GROUP BY local_date ORDER BY local_date;
-- Single-project quantities; client fills missing dates with zero for 7 or 30 calendar days.
SELECT local_date, COALESCE(SUM(amount),0) AS amount FROM entries
WHERE project_id=:project_id AND voided_at_utc_ms IS NULL
 AND local_date BETWEEN :from_date AND :to_date GROUP BY local_date ORDER BY local_date;
-- History pagination: first page omits cursor predicate; fetch page_size+1 to decide has_more.
SELECT * FROM entries WHERE project_id=:project_id AND voided_at_utc_ms IS NULL
 AND (occurred_at_utc_ms < :cursor_time OR (occurred_at_utc_ms=:cursor_time AND id<:cursor_id))
ORDER BY occurred_at_utc_ms DESC,id DESC LIMIT :limit;
