---
name: wizard-refactor
description: Migrate a ComponentEditWizard to the VariantObjectWizard pattern — includes architecture migration, field type mappings, and constants file creation
argument-hint: component to migrate
---

You are helping migrate a ComponentEditWizard to the VariantObjectWizard pattern. The component to migrate: $ARGUMENTS

If a plan file exists at `/Users/matthew/.claude/plans/polymorphic-kindling-clover.md`, read it for current status.

## Architecture Migration

**FROM (Legacy):**
- `ComponentEditWizard` + `{Component}.ts` data loading
- Backend-dependent field definitions via OPTIONS API calls
- Dynamic field rendering based on server response
- `Section.tsx` - Special field handling and overrides

**TO (New):**
- `{Component}Wizard` + `{Component}Form` with `VariantObjectWizard` as parent
- Hardcoded frontend field definitions in `{Component}Form.constants.ts`
- Static field rendering following `MeteringLocationWizard`/`MeteringLocationForm` pattern
- Remove backend dependency for displaying form fields

## New File Structure

```
{Component}Wizard/
├── index.tsx                      # Main wizard component
├── {Component}Form.tsx            # Form component
├── {Component}Form.constants.ts   # Field definitions
└── types.ts                       # TypeScript interfaces
```

## Refactoring Steps

### 1. Analyze Existing Component
1. Locate ComponentEditWizard usage for this component
2. Extract OPTIONS API data — document all field metadata from backend
3. Map conditional logic — identify backend-dependent field visibility rules
4. Document field relationships and complex dependencies

### 2. Create New Architecture
1. Create `{Component}Wizard` main container
2. Create `{Component}Form` with form logic and validation
3. Create `{Component}Form.constants.ts` with hardcoded field definitions
4. Use `VariantObjectWizard` as parent component pattern

### 3. Migration Considerations

**Field Conditional Logic**: Legacy systems rely on backend logic for showing/hiding fields. Implement conditions in React components instead.

**API Integration**: Replace dynamic field discovery (OPTIONS API) with static definitions. Maintain existing data loading for form values.

## Field Type Mappings

| OPTIONS API Type | Frontend Component | Notes |
|---|---|---|
| `string` | `TextInput` / `Textarea` | |
| `integer` | `NumberInput` | |
| `boolean` | `Checkbox` / `Switch` | |
| `choice` | `Select` | Convert `choices` to `data` array |
| `date` | `DateInput` | |
| `image upload` | Custom file upload | |
| `nested object` | Custom component | Requires special handling |

### Field Properties
- `required: true` → Add to validation schema
- `read_only: true` → Display-only or exclude
- `allow_null: true` → Optional validation
- `max_length` → Length validation
- `choices` → Convert to Select options array

## Constants File Pattern

```typescript
export const FIELD_DEFINITIONS = {
  fieldName: {
    type: 'text' | 'number' | 'boolean' | 'select' | 'date',
    label: 'Field Label',
    required: boolean,
    allowNull: boolean,
    choices?: Array<{value: string, label: string}>,
  },
} as const satisfies { ... };
```

### Naming Conventions
- API fields: `snake_case` → Frontend fields: `camelCase`
- Choice values: Keep original backend values
- Labels: Use EXACT labels from OPTIONS API

### Field Exclusions
Intentionally exclude: internal system fields, calculated/derived fields, fields managed by other components, deprecated fields.

## Reference Implementation

Use `MeteringLocationWizard`/`MeteringLocationForm` as the primary reference for component structure, field organization, validation, and error handling.

## Migration Checklist

- [ ] Analyze existing ComponentEditWizard usage
- [ ] Extract and document OPTIONS API field data
- [ ] Create new component file structure
- [ ] Implement hardcoded field definitions
- [ ] Migrate conditional logic
- [ ] Update parent component pattern
- [ ] Test all field types and validations
- [ ] Verify data persistence works
- [ ] Update related tests
- [ ] Remove legacy components
- [ ] Run `/dead-code-cleanup` to clean up references

## Best Practices

1. Start with simple fields (string/number) first
2. Handle complex types (nested objects, file uploads) last
3. Preserve existing validation — don't break working validation
4. Test incrementally — verify each field type as you add it
5. Use MeteringLocation as template for all patterns
