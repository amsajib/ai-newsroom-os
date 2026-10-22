# UI Acceptance Tests

- [ ] Every route handles loading, empty, error, and permission-denied states.
- [ ] User without permission cannot trigger protected mutations even by direct API call.
- [ ] Prompt versions are immutable; activation/rollback is audited.
- [ ] Custom provider secret never reappears after submission or in network/log snapshots.
- [ ] Capability mismatch blocks incompatible model assignment.
- [ ] Claim evidence panel distinguishes verified, partially verified, unverified, contradicted.
- [ ] Material edit after approval removes the publish-ready state.
- [ ] Publish button requires backend eligibility and does not optimistically mark published.
- [ ] Unknown CMS result shows reconciliation workflow.
- [ ] SSE disconnect/reconnect does not duplicate actions or corrupt task state.
- [ ] Mobile layout, keyboard navigation, focus states, screen-reader labels pass.
- [ ] All images show provenance and original/derivative relationship where applicable.
