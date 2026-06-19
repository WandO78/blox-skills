# /blox:deploy — Per-Platform Command Guides

> Basic-mode step-by-step commands for Step 3 (Deploy). SKILL.md keeps the
> 4-step pipeline + detection rules; this holds the verbatim command sequences
> per platform. Load when executing a basic-mode deployment.

## Vercel
```
# First deployment (if not yet connected):
npx vercel --yes                    # Link project
npx vercel env pull .env.local      # Pull env vars

# Production deployment:
npx vercel deploy --prod

# Expected output:
# > Deploying to production
# > https://[project].vercel.app
# > Build completed
# > Deployed to production
```

## Netlify
```
# First deployment:
npx netlify init                    # Link project
npx netlify env:import .env.production  # Import env vars

# Production deployment:
npx netlify deploy --prod --dir=[build-dir]

# Expected output:
# > Deploy is live!
# > https://[project].netlify.app
```

## Fly.io
```
# First deployment:
fly launch                          # Create app
fly secrets import < .env.production  # Set secrets

# Production deployment:
fly deploy

# Expected output:
# > Deploying...
# > Machine started successfully
# > https://[project].fly.dev
```

## Docker (Cloud Run example)
```
# Build and push:
docker build -t gcr.io/[project-id]/[app-name] .
docker push gcr.io/[project-id]/[app-name]

# Deploy:
gcloud run deploy [app-name] \
  --image gcr.io/[project-id]/[app-name] \
  --platform managed \
  --region [region] \
  --allow-unauthenticated

# Expected output:
# > Deploying container...
# > Service URL: https://[app-name]-[hash].run.app
```

## AWS Lambda (Serverless)
```
# Deploy:
npx serverless deploy --stage production

# Expected output:
# > Deploying...
# > Service deployed to stack [name]
# > endpoints:
# >   GET - https://[id].execute-api.[region].amazonaws.com/production/
```

## Rollback commands (per platform)
- Vercel: `vercel rollback`
- Netlify: `netlify deploy --prod --dir=[previous-build]`
- Fly.io: `fly deploy --image [previous-image]`
- Docker/Cloud Run: `gcloud run deploy --image [previous-image]`
