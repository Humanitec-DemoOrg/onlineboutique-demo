```bash
humctl create app-value \
    frontend-message \
    "Secret message" \
    --is-secret \
    --context ${HUMANITEC_CONTEXT}/apps/${APP}

humctl create app-value \
    cymbal-branding \
    false \
    --context ${HUMANITEC_CONTEXT}/apps/${APP}
```