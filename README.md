# Screenshots: QA re-run of kairos-io/kairos#4585 at head `470466a9`

Chrome for Testing 153 headless, 1400x1100, driven over bare CDP against the
guest's forwarded `:8080`. Logs and the result matrix are in the gist linked
from the QA comment.

| file | what it shows |
| --- | --- |
| `01-form.png` | the installer form as served by the in-process web UI |
| `02-form-filled.png` | device `/dev/vda` typed in, cloud-config pasted (it carries `install.device: /dev/SHOULD-BE-OVERRIDDEN`) |
| `03-progress-early.png` | `progress.html` after the redirect |
| `04-progress-mid-1.png`, `04-progress-mid-2.png` | mid-run |
| `05-progress-final.png` | all eight agentrun steps ticked, clean log, Download Logs shown |
| `06-progress-reloaded.png` | a **fresh load** of `progress.html` after the run ended: the full transcript and the finished checklist are replayed |
| `07-failed-install.png` | a failing agent: red `✗` on the step that failed, `[ERROR]` line, and the stub's `ESC[32mINF ESC[0m` rendered with the codes stripped |
| `08-retry-after-failure.png` | the retry after that failure, which started a second agent run |
