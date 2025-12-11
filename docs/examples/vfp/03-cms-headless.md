# VFP-REST: Headless CMS

Content Management System mit Publishing Workflow, Versionierung und Multi-Site Support.

## Architektur

```
┌─────────────────┐                    ┌─────────────────┐
│  Admin Panel    │   VFP-REST         │  CMS Server     │
│  (React)        │ ◄───────────────► │  (PHP/Laravel)  │
└─────────────────┘                    │                 │
                                       │  - Workflows    │
┌─────────────────┐                    │  - Permissions  │
│  Website        │   VFP-REST (GET)   │  - Media        │
│  (Next.js)      │ ◄───────────────► │  - Search       │
└─────────────────┘                    └─────────────────┘
```

## URL Schema

```
/vfp/sites/{siteId}/
    meta.json               Site Konfiguration
    content/
        pages/
            {slug}.json     Seiten
        posts/
            {slug}.json     Blog Posts
        products/
            {sku}.json      Produkte
    media/
        {assetId}/
            meta.json       Asset Metadaten
            original        Original Datei
            thumb           Thumbnail
    schemas/
        page.json           Content Types
        post.json
    users/
        {userId}.json       Benutzer
    workflows/
        {workflowId}.json   Workflow Status
```

## Content erstellen (Draft)

```http
PUT /vfp/sites/blog/content/posts/hello-world.json HTTP/1.1
Content-Type: application/json
X-Vfp-Branch: drafts
X-Vfp-Message: Create new blog post

{
  "slug": "hello-world",
  "title": "Hello World",
  "excerpt": "My first blog post",
  "content": {
    "type": "doc",
    "content": [
      {
        "type": "paragraph",
        "content": [
          { "type": "text", "text": "Welcome to my blog!" }
        ]
      }
    ]
  },
  "author": "user_001",
  "tags": ["intro", "welcome"],
  "status": "draft",
  "publishAt": null,
  "createdAt": 1733400000000,
  "updatedAt": 1733400000000
}
```

**Response:**
```http
HTTP/1.1 201 Created
X-Vfp-Tick: 1
X-Vfp-Branch: drafts
```

## Content bearbeiten

```http
PUT /vfp/sites/blog/content/posts/hello-world.json HTTP/1.1
Content-Type: application/json
X-Vfp-Branch: drafts
If-Match: "v1"
X-Vfp-Message: Add introduction paragraph

{
  "slug": "hello-world",
  "title": "Hello World - Updated",
  "content": { ... },
  "updatedAt": 1733400500000
}
```

## Versionen vergleichen (Diff)

```http
POST /vfp/sites/blog/content/posts/hello-world/_diff HTTP/1.1
Content-Type: application/json

{
  "from_tick": 1,
  "to_tick": 5,
  "content": true
}
```

**Response:**
```json
{
  "changes": [
    {
      "path": "/title",
      "op": "modify",
      "old_value": "Hello World",
      "new_value": "Hello World - Updated"
    },
    {
      "path": "/content/content/1",
      "op": "add",
      "new_value": { "type": "paragraph", "content": [...] }
    }
  ],
  "modifications": 2
}
```

## Publishing Workflow

### 1. Review anfordern

```http
PUT /vfp/sites/blog/workflows/wf_001.json HTTP/1.1
Content-Type: application/json

{
  "id": "wf_001",
  "type": "publish",
  "contentPath": "/content/posts/hello-world.json",
  "status": "pending_review",
  "requestedBy": "user_001",
  "assignedTo": "user_editor",
  "requestedAt": 1733401000000,
  "comments": []
}
```

### 2. Review Kommentar

```http
PUT /vfp/sites/blog/workflows/wf_001.json HTTP/1.1
Content-Type: application/json
If-Match: "wf_v1"

{
  "status": "changes_requested",
  "comments": [
    {
      "author": "user_editor",
      "text": "Please add a featured image",
      "createdAt": 1733402000000
    }
  ]
}
```

### 3. Publish (Merge to main)

```http
POST /vfp/sites/blog/_merge HTTP/1.1
Content-Type: application/json

{
  "source": "drafts",
  "target": "main",
  "strategy": "auto",
  "message": "Publish: Hello World post"
}
```

**Response:**
```json
{
  "version": { "tick": 20, "branch": "main" },
  "conflicts": false
}
```

## Content abrufen (Public API)

```http
GET /vfp/sites/blog/content/posts/hello-world.json HTTP/1.1
X-Vfp-Branch: main
```

## Content Liste mit Filter

```http
GET /vfp/sites/blog/content/posts/_select?filter=status%3Dpublished&sort=publishedAt:desc&limit=10 HTTP/1.1
```

**Response:**
```json
{
  "results": [
    {
      "path": "/content/posts/hello-world.json",
      "data": {
        "slug": "hello-world",
        "title": "Hello World - Updated",
        "excerpt": "My first blog post",
        "publishedAt": 1733403000000
      }
    },
    {
      "path": "/content/posts/second-post.json",
      "data": { ... }
    }
  ],
  "total": 2,
  "has_more": false
}
```

## Media Upload

### 1. Metadata erstellen

```http
PUT /vfp/sites/blog/media/img_001/meta.json HTTP/1.1
Content-Type: application/json

{
  "id": "img_001",
  "name": "header-image.jpg",
  "type": "image/jpeg",
  "size": 245000,
  "width": 1920,
  "height": 1080,
  "alt": "Blog header image",
  "uploadedBy": "user_001",
  "uploadedAt": 1733404000000
}
```

### 2. Binary Upload

```http
PUT /vfp/sites/blog/media/img_001/original HTTP/1.1
Content-Type: image/jpeg
Content-Length: 245000

[Binary JPEG Data]
```

## Scheduled Publishing

```http
PUT /vfp/sites/blog/content/posts/future-post.json HTTP/1.1
Content-Type: application/json

{
  "slug": "future-post",
  "title": "Coming Soon",
  "status": "scheduled",
  "publishAt": 1735689600000
}
```

Server veroeffentlicht automatisch zum geplanten Zeitpunkt.

## Multi-Site Query

```http
GET /vfp/sites/_select?filter=type%3Dblog HTTP/1.1
```

```json
{
  "results": [
    { "path": "/sites/blog", "data": { "name": "Main Blog", "domain": "blog.example.com" } },
    { "path": "/sites/news", "data": { "name": "News Site", "domain": "news.example.com" } }
  ]
}
```

## React Admin Component

```tsx
function PostEditor({ siteId, slug }: Props) {
    const vfp = useVfpClient();
    const [post, setPost] = useState<Post | null>(null);
    const [saving, setSaving] = useState(false);

    useEffect(() => {
        vfp.read(`/sites/${siteId}/content/posts/${slug}.json`, { branch: 'drafts' })
           .then(setPost);
    }, [slug]);

    async function save() {
        setSaving(true);
        await vfp.write(
            `/sites/${siteId}/content/posts/${slug}.json`,
            post,
            { branch: 'drafts', message: `Update: ${post.title}` }
        );
        setSaving(false);
    }

    async function publish() {
        await vfp.merge(siteId, {
            source: 'drafts',
            target: 'main',
            message: `Publish: ${post.title}`
        });
    }

    return (
        <Editor
            value={post}
            onChange={setPost}
            onSave={save}
            onPublish={publish}
        />
    );
}
```