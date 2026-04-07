---
name: e2e-test
description: Write a Playwright E2E test (Python) for a given workflow — includes research, planning, page objects, fixtures, and verification steps
argument-hint: workflow description
---

Write an E2E (Playwright in Python) test for the following workflow: $ARGUMENTS

## Additional resources

- For VariantObjectWizard edit modal tests, see [reference.md](reference.md)

## Prerequisites

The frontend must be built for E2E tests to work locally:
```bash
cd frontend && CI=true BACKEND_BASE_URL="" BACKEND_DAL_API_URL="" npm run build
```
Without `CI=true`, the build bakes in `BACKEND_BASE_URL=http://localhost:8000`, which doesn't match the test server's random port. The fallback (using `window.location`) is what we want.

## Step 1: Research

Understand the workflow and find existing infrastructure to reuse.

### 1a. Explore the UI workflow
- Read the **frontend components** that implement the workflow described above
- Trace the user flow: which pages, modals, forms, and buttons are involved?
- Note exact button labels, heading text, and field labels — the app UI is in German

### 1b. Find existing page objects and helpers
- Check `optinode/webserver/tests/playwright_api/pages.py` for existing page classes
- Check `optinode/webserver/tests/playwright_api/web_elements/forms.py` for form helpers
- Check `optinode/webserver/tests/playwright_api/web_elements/modals.py` for modal helpers
- Check `optinode/webserver/tests/playwright_api/web_elements/fields.py` for field helpers (ReactSelect, Switch)
- Check for feature-specific helpers in `optinode/webserver/tests/` subdirectories

### 1c. Find fixtures and factories
- Check `conftest.py` (root) for core fixtures: `user`, `authenticated_browser_context`, `empty_manager_variant`, `empty_manager_site`, `staff_user`
- Check `optinode/webserver/tests/conftest.py` for page fixtures: `main_page`, `admin_page`
- Check feature-specific conftest files in `optinode/webserver/tests/` subdirectories
- Find relevant factories by searching `optinode/**/tests/factories.py` — common locations:
  - `optinode/webserver/users/tests/factories.py` (UserFactory, OrganizationFactory)
  - `optinode/webserver/configurator/test/factories.py` (SiteFactory, GeneratorFactory, ConsumerFactory, ConnectionFactory, PersonFactory, MeterFactory)
  - `optinode/webserver/customers/tests/factories.py` (CustomerFactory)
  - `optinode/webserver/projects/tests/factories.py` (ProjectFactory)

### 1d. Find similar tests as reference
- Look at existing E2E tests in `optinode/webserver/tests/` for patterns similar to the target workflow
- Note how they set up fixtures, use page objects, and structure assertions

## Step 2: Plan

Present the following plan to the user and **wait for feedback before implementing**:

1. **Test location**: Which file (new or existing) and directory
2. **Fixtures needed**: List fixtures to reuse from conftest, and new fixtures to create
3. **Factories for test data**: Which factories and with what parameters
4. **Page objects**: Existing ones to reuse, new ones to create (with methods)
5. **Step-by-step test flow**: Numbered list of user actions and assertions
6. **Markers**: Which pytest markers are needed

Ask: "Does this plan look correct? Any steps I should add, remove, or change?"

**Do not proceed to Step 3 until the user confirms the plan.**

## Step 3: Implement

### Required markers — every E2E test needs ALL of these
```python
@pytest.mark.endtoend
@pytest.mark.slow
@pytest.mark.django_db
@pytest.mark.allow_django_unsafe_async
```

Add if needed:
- `@pytest.mark.celery` + `@pytest.mark.usefixtures("celery_session_worker")` for tests triggering Celery tasks
- `@flaky(max_runs=3)` for timing-sensitive tests
- `@pytest.mark.xfail(reason=XFailReason.FAILING_CELERY_TASKS)` — ONLY for the Celery teardown race condition (task outlives the test DB transaction). Never use `xfail` to paper over a test that doesn't work yet — get the test assertions passing first, then add `xfail` only if the teardown check fails

### Page object pattern
New page objects subclass `BasePage` and go in `pages.py` or a feature-specific file:
```python
class ExamplePage(BasePage):
    def navigate(self, project: Project, **kwargs):
        url = reverse("manager-projects")
        self.page.goto(f"{url}{project.id}/your-path/")
```

### Form pattern
New forms subclass `BaseForm` with `form_selector` and `submit()`:
```python
class ExampleForm(BaseForm):
    form_selector = ".mantine-Modal-content:has-text('Title')"

    def submit(self):
        self.form_locator.get_by_role("button", name="Speichern").click()
```

**Important:** `form.fill(**{"Label": "value"})` uses `.type()` which **appends** to existing values. For editing pre-filled fields (edit mode), use `.fill()` directly on the locator — it replaces the entire value:
```python
form.form_locator.get_by_role("textbox", name="Bezeichnung").fill("New value")
```

### Fixture pattern
Page fixtures go in a `conftest.py` in the test subdirectory:
```python
@pytest.fixture
def example_page(authenticated_browser_context, some_data_fixture):
    page = authenticated_browser_context.new_page()
    example_page = ExamplePage(page)
    example_page.navigate(...)
    return example_page
```

### Assertions
Use Playwright's `expect()`:
```python
from playwright.sync_api import expect

expect(page.get_by_role("heading", name="Title")).to_be_visible()
expect(page.get_by_text("Success message")).to_be_visible()
```

### Selectors — prefer accessible queries
1. `get_by_role("button", name="Speichern")` — best for buttons and interactive elements
2. `get_by_role("textbox", name="Feldname")` — best for form fields (avoids substring matching issues with `get_by_label`, e.g. "Bezeichnung" matching "Firmenbezeichnung")
3. `get_by_text("Visible text")` — for non-interactive content
4. `locator(".css-selector")` — last resort

**Mantine gotchas:**
- `IconButton` children (e.g. "Liste aktualisieren") are text, not button names — use `get_by_text()` instead of `get_by_role("button", name=...)`
- Mantine's `FormFieldLabel` renders nested `<label>` elements, so `get_by_label()` may fail. Use `locator("input[aria-label*='...']")` for dynamically-labeled fields
- Some UI elements are gated by `useShouldShowStaffView()` which requires `is_staff=True`. Override the `user` fixture in local conftest if your test needs staff-only UI

### Tabbed forms
When a modal has tabs, **all tab panels exist in the DOM simultaneously**. Field selectors like `get_by_role("textbox", name="Ort")` may match fields in inactive tabs. Scope to the active tab panel:
```python
form = EditWizardForm.on_page(base_page=page)
general_tab = form.form_locator.get_by_role("tabpanel")
general_tab.get_by_role("textbox", name="Ort").fill("Berlin")
```

### Tests involving business rules / @catch_missing_data
When a Celery task is decorated with `@catch_missing_data`, it catches `RuleMissedData` exceptions from `@business_rule`-decorated functions. Only `@business_rule` functions trigger the None-field patching — regular Python code just sees `None` without raising.

To control which fields trigger MISSING in a fixture:
1. Search for `@business_rule` in the relevant rules directory (e.g. `regulatory_assessment/rules/`)
2. Check whether each caller catches `RuleMissedData` (if caught → won't propagate to task level)
3. For uncaught paths: populate those model fields with non-None values (e.g. `Option.NO` for EnumFields) to prevent them from triggering MISSING
4. Leave only the ONE field you want to test as None

## Step 4: Verify

Run the test and iterate until it passes:
```bash
just backend-tests-endtoend path/to/test_file.py
```

If it fails:
1. Read the error output carefully — run with `-s --tb=short` to see server logs inline
2. For timing issues: use `expect(...).to_be_visible(timeout=10000)` or add `page.wait_for_load_state("networkidle")`
3. For selector issues: verify exact German text from the frontend components. When stuck, capture the DOM: `print(page.locator("[role='dialog']").inner_html())`
4. For data issues: check that factories create all required related objects
5. For empty page body (no React rendering): the frontend build likely has hardcoded `BACKEND_BASE_URL`. Rebuild with `CI=true`. To confirm, add a console listener in the fixture and look for `ERR_CONNECTION_REFUSED` errors:
   ```python
   page.on("console", lambda msg: print(f"[{msg.type}] {msg.text}"))
   ```
6. For Celery tests where the task runs but teardown fails: this is the known race condition where the task outlives the test DB transaction. Add `@pytest.mark.xfail(reason=XFailReason.FAILING_CELERY_TASKS)` — but only after the test assertions themselves pass
7. Fix and re-run until green

For debugging, run with a visible browser:
```bash
just backend-tests-endtoend path/to/test_file.py --head
```

### Debugging with traces
Playwright automatically saves traces for failed tests in `playwright-traces/` (at project root). Open them with:
```bash
playwright show-trace playwright-traces/<test-name-kebab-case>/trace.zip
```
The trace viewer shows each action step-by-step with DOM snapshots, network requests, and console logs.

For CI failures: download the `e2e_test_report` artifact from the GitHub Actions run — traces are inside under `playwright-traces/`.

Additional recording options:
- `--tracing on` — save traces for all tests (default: only on failure)
- `--video on` — record video of test runs
- `--screenshot on` — capture screenshots
