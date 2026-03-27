---
name: dynamic-form-refactor
description: Migrate a form from OptionsForm/DynamicForm to react-hook-form + FormFieldController — includes field metadata extraction from Django serializers, constants file creation, and TDD story approach
argument-hint: component or form to migrate
---

You are helping migrate a form from OptionsForm/DynamicForm to the react-hook-form + FormFieldController pattern. Task: $ARGUMENTS

## Reference Implementation

Use `ContractForm.tsx` as the canonical example of the target pattern:
- `frontend/app/components/DeliveryOverview/ContractDeliveries/ContractModal/ContractForm/ContractForm.tsx`
- `frontend/app/components/DeliveryOverview/ContractDeliveries/ContractModal/ContractForm/ContractForm.constants.ts`
- `frontend/app/components/DeliveryOverview/ContractDeliveries/ContractModal/ContractForm/ContractFormControls/ContractFormControls.tsx`

ContractForm also uses dynamic field visibility and supports both "new" and "edit" modes — the same patterns most OptionsForm refactors will need.

## Workflow

### Step 1: Understand the current form

1. Read the existing component that uses OptionsForm/DynamicForm
2. Read the accompanying story file — it will have mock OPTIONS data, but **this data may be stale or incomplete**
3. Find the corresponding **Django model and DRF serializer** — these are the source of truth for field metadata

### Step 2: Plan the constants file

Create `ComponentName.constants.ts` with:
- `FORM_FIELD_DATA` — FormInputData definitions for each field (see "Field Metadata" section below)
- `FIELDS_FOR_*` — any dynamic field visibility mappings
- `DEFAULT_VALUES` — default values for "new" mode

### Step 3: Build the form (TDD approach)

1. Write stories FIRST that assert the desired fields are visible/hidden for each mode
2. Implement the form component using `useForm<T>()` + `FormFieldController`
3. Add submit/action buttons directly inside `<ModalFooter>` in the parent modal component — do NOT use portal/ref patterns
4. Update parent components to handle API calls (POST/PUT) — the form only validates and provides data

### Step 4: Update parent components

The form no longer handles API calls internally (OptionsForm did this). Parent components must:
- Extract API calls into a `useMutation` hook in a `hooks/` directory (e.g. `useSubMeteringConfigurationMutations.ts`) — see `frontend/app/components/ThirdPartySystems/hooks/useSubMeteringConfigurationMutations.ts` as reference
- The hook exports a function containing named `useMutation` calls, with the raw API calls extracted to standalone helper functions at the bottom of the file (see `frontend/app/components/Paragraph6/hooks/useParagraph6ContractMutations.ts`)
- **Always add `onSettled: () => queryClient.invalidateQueries({ queryKey: [...] })`** to create and update mutations — use `onSettled` (not `onSuccess`) so the cache is invalidated even on error
- Call `mutation.mutateAsync(data)` in the modal's submit handler; keep local state updates (navigation, toasts, etc.) in the component
- Use `mutation.isPending` for button `loading` props instead of manual `useState` loading flags
- Use `omitNullValues()` when the form has nullable fields that the backend rejects as null

### Step 5: Clean up

- Remove OPTIONS mock data (`FIELD_OPTIONS`, `.onOptions()`) from story files
- Remove OptionsForm/DynamicForm imports
- Run validation commands

## Field Metadata: Django Serializer as Source of Truth

**The Django serializer and model are the authoritative source** for field metadata. The OPTIONS response was auto-generated from these — now you must read them directly.

1. Find the DRF serializer class and its `Meta.fields`
2. For each field, check the **serializer** first (for overrides), then the **model** for defaults
3. Cross-reference every property:
   - **label**: from serializer field `label=` kwarg, or model field `verbose_name`
   - **helpText**: from model field `help_text=` — do NOT omit these
   - **required**: check model `null`/`blank` AND serializer overrides (`required=False`, `allow_blank=True`)
   - **choices**: serializers may limit choices to a subset (e.g. `EnumFieldWithLimitedChoices`) — do NOT use the full enum
   - **maxLength**: from model field `max_length=`

### CRITICAL: EXACT LABEL USAGE

**NEVER INVENT OR MODIFY LABELS**: Always use the EXACT labels from the Django serializer/model. Do not improve, translate, or modify labels even if they seem unclear or could be better.

## Field Type Mappings

| Django / OPTIONS Type | FormInputData Type | Additional Properties |
|---|---|---|
| `CharField` / `"string"` | `"text"` | `maxLength` (from `max_length`) |
| `BooleanField` / `"boolean"` | `"boolean"` | - |
| `IntegerField` / `"integer"` | `"number"` | - |
| `DateField` / `"date"` | `"date"` | - |
| `ChoiceField` / `"choice"` | `"select"` | `data` array from `choices` |
| `EncryptedField` (password-like) | `"password"` | - |

## Field Name Conversion

snake_case API → camelCase frontend:
- `manufacturing_industry` → `manufacturingIndustry`
- `sub_metering_system` → `subMeteringSystem`

## FormInputData Properties

### Required
1. **name**: camelCase version of API field name
2. **label**: EXACT copy from Django source — NEVER modify or invent
3. **type**: Mapped per conversion table
4. **required**: Only include if `true`

### Optional
- **maxLength**: For string fields with `max_length`
- **data**: For select fields, from `choices` array (use EXACT `display_name` values mapped to `label`)
- **helpText**: From model field `help_text` — include for ALL fields that have it
- **placeholder**: For example values

## Constants File Pattern

```typescript
export const FORM_FIELD_DATA = {
  fieldName: {
    name: "fieldName",
    label: "Exact Label",
    type: "text",
    required: true
  },
} as const;
```

## Stories Checklist

- [ ] **NewMode** story — empty form, verify initial field visibility
- [ ] **EditMode** story — pre-populated, verify values are filled and any read-only fields are disabled
- [ ] **FieldVisibility** story (if dynamic) — test field show/hide based on selections
- [ ] **FormSubmission** story — fill fields, submit, verify `onSubmit` called with expected data
- [ ] All stories use `play` functions with `step`, `canvas`, `await expect`, `toBeVisible`
- [ ] Use `getByRole` over `getByLabelText` — prefer `getByRole("combobox", { name: "..." })` for selects, `getByRole("textbox", { name: "..." })` for text inputs; fall back to `getByLabelText` only for password inputs (no ARIA role)
- [ ] No OPTIONS mocks (`.onOptions()`) — form is fully static

## Validation Checklist

- [ ] Field names properly converted from snake_case to camelCase
- [ ] Labels match Django source EXACTLY
- [ ] Type mappings follow conversion rules
- [ ] Select fields have properly formatted `data` arrays with EXACT choice labels
- [ ] Required fields marked correctly
- [ ] String fields include `maxLength` where appropriate
- [ ] helpText included for ALL fields that have `help_text` in the Django model
- [ ] Choice fields use the serializer's restricted choices, not the full enum
- [ ] Default values use `null` (not `""`) for nullable fields (`null | string` in TS type)
- [ ] Parent components use `omitNullValues()` when submitting nullable form data
- [ ] Create and update mutations call `invalidateQueries` in `onSettled`
- [ ] All reference fields are represented (unless intentionally excluded)
- [ ] `npx tsc --noEmit` passes
- [ ] `npx eslint` passes on changed files
- [ ] `npx prettier --write` applied to changed files
- [ ] Storybook tests pass

## Reference Patterns

- **ContractForm**: `frontend/app/components/DeliveryOverview/ContractDeliveries/ContractModal/ContractForm/`
- **SubMeteringConfigurationForm**: `frontend/app/components/ThirdPartySystems/SubMeteringConfigurationForm/`
- **Existing constants**: `PersonForm.constants.ts`, `MeteringLocationForm.constants.ts`
