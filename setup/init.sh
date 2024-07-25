
#!/bin/bash
set -e -o pipefail

JQ_PATH="/c/Users/ADMIN/jq.exe"

# Fetch IAM github-action-user ARN
echo "Fetching IAM github-action-user ARN"
userarn=$(aws iam get-user --user-name github-action-user | "$JQ_PATH" -r .User.Arn)

# Download tool for manipulating aws-auth
echo "Downloading tool..."
curl -X GET -L https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v0.6.2/aws-iam-authenticator_0.6.2_windows_amd64.exe -o aws-iam-authenticator.exe

# Check if the aws-iam-authenticator is executable
if [ ! -x "./aws-iam-authenticator.exe" ]; then
  echo "Error: aws-iam-authenticator.exe is not executable or not found"
  exit 1
fi

# Fetch current aws-auth ConfigMap
current_config=$(kubectl get configmap aws-auth -n kube-system -o yaml)

# Check if the user ARN already exists in the ConfigMap
if echo "$current_config" | grep -q "$userarn"; then
  echo "User ARN $userarn already exists in aws-auth ConfigMap. Skipping add user operation."
else
  # Update permissions
  echo "Updating permissions"
  ./aws-iam-authenticator.exe add user --userarn="${userarn}" --username=github-action-role --groups=system:masters --kubeconfig="$HOME"/.kube/config --prompt=false
fi

# Clean up
echo "Cleaning up"
rm aws-iam-authenticator.exe
echo "Done!"