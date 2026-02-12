# Schema Changelog

## 2026-02-08 - Initial XML Schema Release

### Added

#### Component Schema (v1.0)
- **File**: `synth/component/1.0/component.xsd`
- **Namespace**: `https://chevp.github.io/synth-protocol/schema/synth/component/1.0`
- **Purpose**: XML Schema Definition for Synth component files
- **Root Element**: `<synthComponent>`
- **Features**:
  - Metadata (name, type, description)
  - Mesh references
  - Properties with typed values (string, int, float, bool, vec2, vec3, color)
  - UI Layout definitions (panels, widgets)
  - State Machines (FSM support)

#### Scene Schema (v1.0)
- **File**: `synth/scene/1.0/scene.xsd`
- **Namespace**: `https://chevp.github.io/synth-protocol/schema/synth/scene/1.0`
- **Purpose**: XML Schema Definition for Synth scene files
- **Root Element**: `<synthScene>`
- **Features**:
  - Scene metadata
  - Camera settings (orthographic, perspective)
  - API bindings
  - Entity hierarchy with nesting
  - Component references
  - Transform (position, rotation, scale)
  - Point lights
  - Properties

#### GitHub Pages Setup
- **.nojekyll** - Disables Jekyll processing
- **docs/schema/index.html** - Schema documentation landing page
- **docs/schema/catalog.xml** - XML catalog for IDE integration
- **docs/schema/README.md** - Complete documentation
- **docs/schema/examples/** - Example XML files with schema validation
- **docs/GITHUB_PAGES_SETUP.md** - Setup instructions

#### IDE Integration
- **catalog.xml** - Maps public URLs to local files
- **synth-game/.vscode/settings.json** - VSCode configuration for automatic schema resolution

### Schema URLs

When GitHub Pages is activated, schemas will be available at:
- Component: `https://chevp.github.io/synth-protocol/schema/synth/component/1.0/component.xsd`
- Scene: `https://chevp.github.io/synth-protocol/schema/synth/scene/1.0/scene.xsd`
- Project: `https://chevp.github.io/synth-protocol/schema/synth/project/1.0/project.xsd`

### Usage Example

```xml
<?xml version="1.0" encoding="UTF-8"?>
<synthComponent version="1.0" id="my-component"
                xmlns="https://chevp.github.io/synth-protocol/schema/synth/component/1.0">
    <metadata>
        <name>My Component</name>
        <type>custom</type>
    </metadata>
    <properties>
        <property name="enabled" type="bool" value="true"/>
    </properties>
</synthComponent>
```

### Migration Notes

- All `synth-component` tags in synth-game XML files have been renamed to `synthComponent`
- XML namespaces now point to GitHub Pages URLs (will work once Pages is activated)
- Local development uses XML catalog for offline schema resolution

### Next Steps

1. Activate GitHub Pages in synth-protocol repository
2. Test schema URLs
3. Validate all synth-game XML files against schemas
4. Add schema validation to CI/CD pipeline
