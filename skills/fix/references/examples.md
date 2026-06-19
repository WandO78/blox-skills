# /blox:fix — Worked Examples

Worked debugging walkthroughs. The methodology lives in `superpowers:systematic-debugging`;
these illustrate how the blox overlay (checklist marks, commit with root cause) wraps it.

---

## Example 1: Test failing after code change

```
User: "/blox:fix — the login test is failing"

REPRODUCE
  Run: npm test -- --grep "login"
  → FAIL: "Expected 200, got 401"
  Reproducible: yes

GATHER EVIDENCE
  Error: test/auth.test.ts:42 — Expected status 200, received 401
  git log -5 → commit abc123 "feat: update auth middleware to validate token format"
  git diff abc123~1 → middleware now checks for "Bearer v2:" prefix
  Test fixture uses "Bearer eyJhb..." (old format)

FORM HYPOTHESIS
  1. [MOST LIKELY] "The new middleware rejects tokens without the v2 prefix,
     but the test fixture uses the old format"
     - Test: check the test fixture's token format against middleware validation

TEST HYPOTHESIS
  Read test fixture → token starts with "Bearer eyJhb..." (old format)
  Read middleware → rejects tokens without "Bearer v2:" prefix
  → CONFIRMED: format mismatch

WRITE FAILING TEST
  test("auth accepts both old and new token formats", () => {
    expect(validateToken("Bearer eyJhb...")).toBe(true);   // old format (backward compat)
    expect(validateToken("Bearer v2:eyJhb...")).toBe(true); // new format
  });
  → Run: FAIL ✓ (old format rejected)

IMPLEMENT FIX
  Update middleware: accept both "Bearer " and "Bearer v2:" prefixes
  → Bug test: PASS ✓   → All tests: 48/48 PASS ✓

VERIFY AND COMMIT (blox overlay)
  npm test → 48/48 PASS;  npm run lint → clean
  git add src/middleware/auth.ts test/auth.test.ts
  git commit -m "fix: auth middleware accepts both token formats — v2 prefix
  validation was too strict, rejecting valid old-format tokens during migration"
  Phase checklist: mark the auth item [x]
```

---

## Example 2: Runtime error — blank page

```
User: "/blox:fix — the dashboard shows a blank page"

REPRODUCE
  Open dashboard URL → blank page
  Browser console → TypeError: Cannot read property 'map' of undefined
  Reproducible: yes (every page load)

GATHER EVIDENCE
  Error: src/components/Dashboard.tsx:28 — data.map is not a function
  Stack trace: Dashboard → useEffect → fetchData → render
  git log -5 → commit def456 "feat: wrap API responses in {data: [...]} format"
  git diff def456~1 → API now returns {data: [...]} instead of [...]
  Dashboard code: const items = await fetch("/api/items"); items.map(...)

FORM HYPOTHESIS
  1. [MOST LIKELY] "API returns {data: [...]} object instead of [...] array,
     but Dashboard.tsx expects a plain array"
     - Test: inspect actual API response format

TEST HYPOTHESIS
  curl /api/items → {"data": [{"id": 1, ...}]}
  Dashboard code expects: [...] (plain array)
  → CONFIRMED: response format mismatch

WRITE FAILING TEST
  test("Dashboard handles wrapped API response", () => {
    const mockResponse = { data: [{ id: 1, name: "Item 1" }] };
    render(<Dashboard data={mockResponse} />);
    expect(screen.getByText("Item 1")).toBeInTheDocument();
  });
  → Run: FAIL ✓ (TypeError: data.map is not a function)

IMPLEMENT FIX
  Update Dashboard.tsx: unwrap .data from API response
  const response = await fetch("/api/items");
  const { data: items } = await response.json();
  → Bug test: PASS ✓   → All tests: 92/92 PASS ✓

VERIFY AND COMMIT (blox overlay)
  npm test → 92/92 PASS;  npm run lint → clean;  npm run build → success
  git add src/components/Dashboard.tsx test/Dashboard.test.tsx
  git commit -m "fix: Dashboard unwraps {data} from API response —
  API format changed from array to {data: array} in def456"
```

---

## Example 3: Stuck — all hypotheses rejected (loop back, find deeper cause)

```
User: "/blox:fix — file uploads fail silently"

REPRODUCE
  Upload a file → no error message, but file doesn't appear
  Reproducible: yes

GATHER EVIDENCE (Cycle 1)
  No error in browser console; no error in server logs
  git log -10 → no recent upload-related changes
  Network tab → POST /api/upload returns 200; but file not in storage bucket

FORM + TEST HYPOTHESIS (Cycle 1)
  1. "Storage bucket permissions changed" → checked, write access OK → REJECTED
  2. "Upload path misconfigured" → checked config, path correct → REJECTED
  3. "File saved but listing endpoint broken" → manual bucket check, file not there → REJECTED

GATHER EVIDENCE (Cycle 2 — deeper)
  Read upload handler code → try/catch swallows error, returns 200 always
  Add temporary log in catch block → re-test
  Error: "ENOSPC: no space left on device"

FORM + TEST HYPOTHESIS (Cycle 2)
  1. "Server disk is full, upload fails silently because error is caught"
  df -h → /tmp is 100% full → CONFIRMED: disk full + silent error swallowing

WRITE TEST → FIX → VERIFY
  Test error handling (throw instead of swallow), clean up /tmp,
  commit with root cause documented. Remove the temporary log before commit.
```

---

## Example 4: Stuck after 3 cycles — escalate (STUCK PROTOCOL)

```
REPRODUCE..TEST: three full cycles completed, all hypotheses rejected

STOP — Escalate to user:

"I've tested 8 hypotheses across 3 investigation cycles and none
explain why the WebSocket connection drops after exactly 30 seconds:

Cycle 1:
1. Server timeout configuration → REJECTED (set to 120s)
2. Client heartbeat interval → REJECTED (sending every 15s)
3. Proxy timeout → REJECTED (nginx proxy_read_timeout is 300s)

Cycle 2:
4. Load balancer idle timeout → REJECTED (checked AWS ALB: 60s)
5. Connection pool exhaustion → REJECTED (pool at 20% capacity)

Cycle 3:
6. SSL/TLS renegotiation → REJECTED (no renegotiation in logs)
7. Memory leak causing GC pause → REJECTED (heap stable)
8. Firewall rule → REJECTED (no drops in firewall logs)

I need more information to continue. Could you:
a) Check if this happens on all network paths (VPN vs direct)
b) Run a packet capture during the disconnect: tcpdump -i eth0 port 443
c) Tell me if the 30-second timing is exact or approximate"
```
