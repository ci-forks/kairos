# QA proofs for kairos-io/kairos#4662

`fix(state): name the architecture on the images sysinfo cannot read`
BASE `96ef1c97d` vs PR `a902edec0`, on a live Hadron (musl) system booted in QEMU.

| file | what it shows |
| --- | --- |
| `proofs/1-state-get-architecture.png` | `kairos-agent state get system.os.architecture`: BASE `<nil>`, PR `amd64`, on a rootfs with no glibc loader |
| `proofs/2-render-template-and-state-block.png` | `render-template` renders `arch=[]` on BASE and `arch=[amd64]` on PR; the `os:` block of `state` side by side |
| `proofs/hadron-live-ab.mp4` | screen recording of the A/B on the guest console |
| `proofs/qa-proof.log` | full log: e2e, arch/libc matrix, test suites, mutation check |
