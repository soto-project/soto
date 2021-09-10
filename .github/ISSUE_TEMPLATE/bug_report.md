---
name: Bug report
about: Create a report to help us improve the functionality of Soto. If want to know how to do something then ask a question in the discussions Q&A section.
title: ''
labels: ''
assignees: ''

---

**Describe the bug**
A clear and concise description of what the bug is. If you can include a link to redacted requests or responses, that would be very helpful as well!

**To Reproduce**
Steps to reproduce the behavior:
1. ...
2. ...

**Expected behavior**
A clear and concise description of what you expected to happen.

**Setup (please complete the following information):**
 - OS:
 - Version of soto:
 - Authentication mechanism [hard-coded credentials, IAM Instance Profile on EC2, etc]

**Additional context**
Add any other context about the problem here. If this a bug related to a command not working can you run the same command on a client initialised with the logging middleware. eg `S3(region: .useast1).with(middlewares: [AWSLoggingMiddleware()])`
