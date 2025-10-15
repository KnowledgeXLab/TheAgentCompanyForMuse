#!/bin/bash
set -e

# ===================== Configurable variables =====================
API_KEY="${LITELLM_API_KEY:-your_api_key_here}"
BASE_URL="${LITELLM_BASE_URL:-https://example.com/v1}"
LLM="${LITELLM_MODEL:-gpt-4o}"
MUSE_DIR="${MUSE_DIR:-$PWD/MUSE}"   # The MUSE folder in the current directory is mounted by default
BASE_LOG_DIR="./logs"
# ======================================================

cleanup() {
    echo "Capture the interrupt signal. Cleaning up any remaining containers and resources..."
    docker ps -a --filter "name=-image" --format "{{.ID}}" | xargs -r docker rm -f
    docker volume prune -f
    exit 1
}

trap cleanup SIGINT SIGTERM

run_tasks() {
    local TASK_ARRAY=("${!1}")
    local N="$2"
    local AGENT_NAME="$3"
    local MODE="$4"
    local LLM="$5"

    for ((n=1; n<=N; n++)); do
        echo "=========================== [$AGENT_NAME][$MODE] Run round ${n}/${N} ==========================="
        for TASK_NAME in "${TASK_ARRAY[@]}"; do
            IMAGE_NAME="ghcr.io/theagentcompany/${TASK_NAME}-image:1.0.0"
            CONTAINER_NAME="${TASK_NAME}-image"
            LOG_DIR="${BASE_LOG_DIR}/${AGENT_NAME}/${MODE}/${TASK_NAME}"
            mkdir -p "$LOG_DIR"

            LOG_FILE="${LOG_DIR}/${n}.log"
            echo "[$AGENT_NAME][$MODE][$TASK_NAME] ${n}th execution, log path: $LOG_FILE"

            docker run --rm --network host \
                --name "${CONTAINER_NAME}" -i \
                -v "${MUSE_DIR}":/MUSE \
                -v "$PWD/index.js":/usr/local/lib/python3.12/site-packages/browser_use/dom/dom_tree/index.js \
                "$IMAGE_NAME" /bin/bash <<EOF | tee "$LOG_FILE"
export LITELLM_API_KEY=${API_KEY}
export LITELLM_BASE_URL=${BASE_URL}
export LITELLM_MODEL=${LLM}

bash /utils/init.sh

cd /MUSE
python run.py --agent_name "${AGENT_NAME}" --task_name "${TASK_NAME}" --task "\$(cat /instruction/task.md)" --mode "${MODE}" --round "${n}" --llm "${LLM}"
EOF
            docker volume prune -f
            echo "✅ [$TASK_NAME] ${n}th execution completed."
        done
        echo "======================= [$AGENT_NAME][$MODE] All tasks in round ${n} are completed ======================="
        echo "------------------------------------------------------------------------------------------------------------"
    done
}

NORMAL_TASKS=(
    "hr-collect-feedbacks"
    "hr-new-grad-job-description-3"
    "admin-check-employees-budget-and-reply-and-record"
    "ds-sql-exercise"
    "finance-check-attendance-payroll"
    "pm-create-channel-message-medium"
    "pm-update-plane-issue-from-gitlab-status"
    "sde-update-issue-status-on-plane"
    "sde-update-dev-document"
    "hr-transfer-group"
    "hr-check-attendance-multiple-days-department-with-chat"
    "admin-read-survey-and-summarise"
    "ds-answer-spreadsheet-questions"
    "ds-visualize-data-in-pie-and-bar-chart"
    "finance-budget-variance"
    "pm-ask-for-issue-and-create-in-gitlab"
    "pm-check-backlog-update-issues"
    "sde-add-all-repos-to-docs"
)

HARD_TASKS=(
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
)

AGENT_NAME="MUSE"

run_tasks HARD_TASKS[@] 1 "${AGENT_NAME}_test" "test" "${LLM}"

# run_tasks NORMAL_TASKS[@] 1 "${AGENT_NAME}_1" "train" "${LLM}"
# run_tasks NORMAL_TASKS[@] 1 "${AGENT_NAME}_2" "train" "${LLM}"
# run_tasks NORMAL_TASKS[@] 1 "${AGENT_NAME}_3" "train" "${LLM}"

echo "All tasks completed. Logs are saved in $BASE_LOG_DIR"
echo "All tasks are completed, and docker system resources are cleaned up uniformly"
docker system prune -f
