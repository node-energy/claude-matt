# E2E Test Reference: VariantObjectWizard Edit Modals

## EditWizardForm

Use `EditWizardForm` from `optinode/webserver/tests/playwright_api/web_elements/forms.py` for any VariantObjectWizard edit modal. Do **not** create a new form class — this shared class works for all edit wizards (Person, Generator, Consumer, etc.):

```python
from optinode.webserver.tests.playwright_api.web_elements.forms import EditWizardForm

form = EditWizardForm.on_page(base_page=page)
form.submit()  # clicks "Speichern" in the ModalFooter
```

## Example test

See `optinode/webserver/tests/manager/person_edit/` for a complete example of:
- Direct URL navigation to an edit modal
- Editing pre-filled fields (clear + fill pattern)
- Scoping selectors to the active tab panel
- Verifying data persistence by reopening the modal after save

## Assertion best practices

- When asserting that an element is **not** in the DOM, prefer `expect(locator).not_to_be_visible()` over `expect(locator).to_have_count(0)`. The visibility assertion has built-in auto-waiting/retry logic and produces clearer failure messages.
