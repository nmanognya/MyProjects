package main

import rego.v1

deny contains msg if {
  input.kind == "Deployment"
  not input.spec.template.spec.securityContext.runAsNonRoot == true
  msg := sprintf("Deployment %q must set pod securityContext.runAsNonRoot=true", [input.metadata.name])
}

deny contains msg if {
  input.kind == "Deployment"
  not input.spec.template.spec.securityContext.seccompProfile.type == "RuntimeDefault"
  msg := sprintf("Deployment %q must use the RuntimeDefault seccomp profile", [input.metadata.name])
}

deny contains msg if {
  input.kind == "Deployment"
  some container in input.spec.template.spec.containers
  not container.securityContext.allowPrivilegeEscalation == false
  msg := sprintf("Container %q in Deployment %q must disable privilege escalation", [container.name, input.metadata.name])
}

deny contains msg if {
  input.kind == "Deployment"
  some container in input.spec.template.spec.containers
  not container.securityContext.readOnlyRootFilesystem == true
  msg := sprintf("Container %q in Deployment %q must use a read-only root filesystem", [container.name, input.metadata.name])
}

deny contains msg if {
  input.kind == "Deployment"
  some container in input.spec.template.spec.containers
  not "ALL" in container.securityContext.capabilities.drop
  msg := sprintf("Container %q in Deployment %q must drop ALL Linux capabilities", [container.name, input.metadata.name])
}

deny contains msg if {
  input.kind == "Deployment"
  some container in input.spec.template.spec.containers
  not container.resources.requests.cpu
  msg := sprintf("Container %q in Deployment %q must define a CPU request", [container.name, input.metadata.name])
}

deny contains msg if {
  input.kind == "Deployment"
  some container in input.spec.template.spec.containers
  not container.resources.requests.memory
  msg := sprintf("Container %q in Deployment %q must define a memory request", [container.name, input.metadata.name])
}

deny contains msg if {
  input.kind == "Deployment"
  some container in input.spec.template.spec.containers
  not container.resources.limits.cpu
  msg := sprintf("Container %q in Deployment %q must define a CPU limit", [container.name, input.metadata.name])
}

deny contains msg if {
  input.kind == "Deployment"
  some container in input.spec.template.spec.containers
  not container.resources.limits.memory
  msg := sprintf("Container %q in Deployment %q must define a memory limit", [container.name, input.metadata.name])
}

deny contains msg if {
  input.kind == "Deployment"
  not input.spec.template.spec.automountServiceAccountToken == false
  msg := sprintf("Deployment %q must disable automatic ServiceAccount token mounting", [input.metadata.name])
}

deny contains msg if {
  input.kind == "Service"
  input.spec.type == "LoadBalancer"
  msg := sprintf("Service %q must not expose the reference workload directly as a LoadBalancer", [input.metadata.name])
}
