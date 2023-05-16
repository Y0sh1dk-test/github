#!/bin/bash

set -euo pipefail

tf_plan_file=tfplan
tf_plan_file_json=${tf_plan_file}.json

output_up_migration_file=scripts/import_repos_up_migration.sh
output_down_migration_file=scripts/import_repos_down_migration.sh

# Prepare environment
rm ${output_up_migration_file} >/dev/null 2>&1 || true
rm ${output_down_migration_file} >/dev/null 2>&1 || true
rm ${tf_plan_file} >/dev/null 2>&1 || true
rm ${tf_plan_file_json} >/dev/null 2>&1 || true

script_string=$(
    cat <<-END
#!/bin/bash

set -euo pipefail

END
)

# Generate json Terraform Plan
echo "Running Terraform plan..."
terraform plan --out=${tf_plan_file} >/dev/null 2>&1
terraform show -json tfplan | jq '.' >${tf_plan_file_json}
echo "Terraform plan complete!"

# Parse plan to find resources that need to be imported
tf_github_repository_imports=$(jq --raw-output '.resource_changes[] | select(.change.actions[0]=="create") | select(.type=="github_repository") | select(.name="this") | .index' tfplan.json | jq -cRs 'split("\n")[:-1]')

if [ "$tf_github_repository_imports" == "[]" ]; then
    echo "No resources to import!"
    echo "Cleaning up..."
    rm ${tf_plan_file} ${tf_plan_file_json} >/dev/null 2>&1
    echo "Cleanup complete!"
    exit 0
fi

# Populate migration scripts
echo "${script_string}" >>${output_up_migration_file}
echo "${script_string}" >>${output_down_migration_file}

# Subnets
echo "Generating up/down migration scripts"
echo "### GitHub Repository imports ###" >>${output_up_migration_file}
echo "### GitHub Repository imports ###" >>${output_down_migration_file}
echo "${tf_github_repository_imports}" | jq -c --raw-output '.[]' | while read -r i; do
    echo "terraform import github_repository.this[\\\"${i}\\\"] ${i}" >>${output_up_migration_file}
    echo "terraform state rm github_repository.this[\\\"${i}\\\"]" >>${output_down_migration_file}
done

echo "Up migration script ${output_up_migration_file} created!"
echo "Up migration script ${output_down_migration_file} created!"

# Make migration files executable
chmod +x ${output_up_migration_file}
chmod +x ${output_down_migration_file}

# Remove temporary files
echo "Cleaning up..."
rm ${tf_plan_file} ${tf_plan_file_json} >/dev/null 2>&1
echo "Cleanup complete!"
