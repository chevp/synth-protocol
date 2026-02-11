# Synth Protocol - XML Schemas

This directory contains XML Schema Definitions (XSD) for the Synth Protocol.

## Available Schemas

### Component Schema
- **Location**: `synth/component/1.0/component.xsd`
- **Namespace**: `https://chevp.github.io/synth-protocol/schema/synth/component/1.0`
- **Purpose**: Schema for Synth component definitions (`.synth.xml` files)
- **Root Element**: `<synthComponent>`

### Scene Schema
- **Location**: `synth/scene/1.0/scene.xsd`
- **Namespace**: `https://chevp.github.io/synth-protocol/schema/synth/scene/1.0`
- **Purpose**: Schema for Synth scene definitions (scene `.synth.xml` files)
- **Root Element**: `<synth-scene>`

### Project Schema
- **Location**: `synth/project/1.0/project.xsd`
- **Namespace**: `https://chevp.github.io/synth-protocol/schema/synth/project/1.0`
- **Purpose**: Schema for Synth project configuration
- **Root Element**: `<synthProject>`

## Usage

### Basic XML Reference

```xml
<?xml version="1.0" encoding="UTF-8"?>
<synthComponent version="1.0" id="my-component"
                xmlns="https://chevp.github.io/synth-protocol/schema/synth/component/1.0">
    <metadata>
        <name>My Component</name>
        <type>custom</type>
    </metadata>
</synthComponent>
```

### With Schema Validation

```xml
<?xml version="1.0" encoding="UTF-8"?>
<synthComponent version="1.0" id="my-component"
                xmlns="https://chevp.github.io/synth-protocol/schema/synth/component/1.0"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xsi:schemaLocation="https://chevp.github.io/synth-protocol/schema/synth/component/1.0
                                    https://chevp.github.io/synth-protocol/schema/synth/component/1.0/component.xsd">
    <metadata>
        <name>My Component</name>
        <type>custom</type>
    </metadata>
</synthComponent>
```

## IDE Configuration

### Visual Studio Code

1. Install the **XML** extension by Red Hat
2. Add to your workspace settings (`.vscode/settings.json`):

```json
{
  "xml.catalogs": [
    "synth/synth-protocol/docs/schema/catalog.xml"
  ]
}
```

### IntelliJ IDEA / WebStorm

1. Go to **Settings** → **Languages & Frameworks** → **Schemas and DTDs**
2. Click **+** to add a new schema
3. Add the catalog file: `synth/synth-protocol/docs/schema/catalog.xml`

### Oxygen XML Editor

1. Go to **Options** → **Preferences** → **XML** → **XML Catalog**
2. Add the catalog file: `synth/synth-protocol/docs/schema/catalog.xml`

## Local Development

For local development, the XML catalog (`catalog.xml`) maps the public schema URLs to local file paths. This allows your IDE to validate XML files offline.

### Testing Schema Validation

```bash
# Using xmllint (Linux/macOS)
xmllint --schema synth/component/1.0/component.xsd your-component.synth.xml

# Using msxsl (Windows with MSXML)
# Install from: https://www.microsoft.com/download/details.aspx?id=21714
```

## GitHub Pages Hosting

These schemas are also hosted via GitHub Pages at:

- **Component**: https://chevp.github.io/synth-protocol/schema/synth/component/1.0/component.xsd
- **Scene**: https://chevp.github.io/synth-protocol/schema/synth/scene/1.0/scene.xsd
- **Project**: https://chevp.github.io/synth-protocol/schema/synth/project/1.0/project.xsd

### Enabling GitHub Pages

1. Go to your repository settings
2. Navigate to **Pages**
3. Set **Source** to `main` branch, `/docs` folder
4. Save

The schemas will be accessible at `https://chevp.github.io/synth-protocol/schema/...`

## File Structure

```
docs/schema/
├── catalog.xml              # XML catalog for local resolution
├── index.html               # Schema documentation page
├── README.md                # This file
└── synth/
    ├── component/
    │   └── 1.0/
    │       └── component.xsd
    ├── scene/
    │   └── 1.0/
    │       └── scene.xsd
    ├── project/
    │   └── 1.0/
    │       └── project.xsd
    ├── core/
    │   └── 1.0/
    │       └── core.xsd
    ├── events/
    │   └── 1.0/
    │       └── events.xsd
    ├── mcp/
    │   └── 1.0/
    │       └── mcp.xsd
    └── security/
        └── 1.0/
            └── security.xsd
```

## Contributing

When adding new schemas:

1. Create a new version directory (e.g., `synth/component/2.0/`)
2. Add the schema file
3. Update `catalog.xml` with the new schema mapping
4. Update `index.html` with the new schema link
5. Update this README

## License

Part of the [Synth Protocol](https://github.com/chevp/synth-protocol) project.
