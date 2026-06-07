# Aretay Backend

Backend service for the [Aretay iOS app](https://github.com/WillReynolds5/aretay-ios).

> 🚧 Stack not yet chosen — this repo is a placeholder until we pick a framework
> (FastAPI / Hono / Go / Supabase / etc.) and scaffold it.

## Repo layout (planned)

```
aretay-backend/
├── README.md
├── .gitignore
└── (stack files coming soon)
```

## Mono layout

This repo lives alongside the iOS app in a local mono directory:

```
aretay-mono/
├── aretay-ios/        # SwiftUI iOS app — separate git repo
└── aretay-backend/    # this repo — separate git repo
```

Each subfolder is its own independent git repository pushed to its own GitHub remote.
