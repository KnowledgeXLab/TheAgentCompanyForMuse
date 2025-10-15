#!/bin/bash
set -e

# Optional: enable debug output
if [ -n "$DEBUG" ]; then
    set -x
fi

cd base_image
make build
cd ..

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TASKS_DIR="$SCRIPT_DIR/tasks"
VERSION="1.0.0"
REGISTRY_PREFIX="ghcr.io/theagentcompany"

TARGET_TASKS=(
    "hr-collect-feedbacks"
    "hr-new-grad-job-description-3"
    "admin-check-employees-budget-and-reply-and-record"
    "ds-sql-exercise"
    "finance-check-attendance-payroll"
    "pm-create-channel-message-medium"
    "pm-update-plane-issue-from-gitlab-status"
    "sde-update-issue-status-on-plane"
    "sde-update-dev-document"
    "sde-copilot-arena-server-new-endpoint"

    "hr-transfer-group"
    "ds-predictive-modeling"
    "hr-transfer-group"
    "hr-check-attendance-multiple-days-department-with-chat"
    "admin-read-survey-and-summarise"
    "ds-answer-spreadsheet-questions"
    "ds-visualize-data-in-pie-and-bar-chart"
    "finance-budget-variance"
    "pm-ask-for-issue-and-create-in-gitlab"
    "pm-check-backlog-update-issues"
    "sde-add-all-repos-to-docs"

    "hr-internal-tooling-slides"
    "hr-salary-analysis"
    "finance-invoice-matching"
    "finance-nonqualified-bill-ask-for-reimburse"
    "ds-calculate-spreadsheet-stats"
    "ds-predictive-modeling"
    "admin-mass-forms-filling"
    "pm-present-engineer-group-members"
    "sde-copy-table-from-pdf-to-xlsx"
    "sde-sotopia-create-agent-wo-repo"
    "hr-mass-survey"
    "sde-create-commit-table-for-all-gitlab-users"
    "finance-create-10k-income-report"
)

# `ALL` mode, when turned on, all tasks will be built
BUILD_ALL=false
if [[ "$1" == "--all" ]]; then
    BUILD_ALL=true
fi

if $BUILD_ALL; then
    echo "🔍 Building ALL tasks under $TASKS_DIR"
else
    echo "🔍 Tasks to be built: ${TARGET_TASKS[*]}"
fi

# Build each task
for task_dir in "$TASKS_DIR"/*/; do
    task_name=$(basename "$task_dir")
    dockerfile_path="${task_dir}/Dockerfile"

    if ! $BUILD_ALL; then
        if [[ ! " ${TARGET_TASKS[*]} " =~ " ${task_name} " ]]; then
            echo "⏭️  Skipping $task_name - not in target task list"
            continue
        fi
    fi

    # Skip if no Dockerfile
    if [ ! -f "$dockerfile_path" ]; then
        echo "⏭️  Skipping $task_name - no Dockerfile"
        continue
    fi

    image_name="${REGISTRY_PREFIX}/${task_name}-image:${VERSION}"
    
    echo "🐳 Building image: $image_name"

    (
        cd "$task_dir"
        docker rmi "$image_name" || true
        docker build -t "$image_name" .
    )

    echo "✅ Built $image_name"
done

echo "🎉 Task images built successfully."
