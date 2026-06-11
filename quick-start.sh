#!/bin/bash
#
# quick-start.sh
# Wiki.js deployment quick-start with detection for existing installations.
# Supports both fresh setup and maintenance of existing deployments.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# Utility Functions
# =============================================================================

# read_prompt
# Reads user input with a prompt.
read_prompt() {
    local prompt="$1"
    local var_name="$2"
    read -r -p "$prompt" "$var_name"
}

# check_docker_swarm
# Verifies Docker is running and Swarm is initialized.
check_docker_swarm() {
    if ! docker info >/dev/null 2>&1; then
        echo "❌ Docker is not running"
        return 1
    fi
    
    if ! docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null | grep -q "active"; then
        echo "❌ Docker Swarm is not initialized"
        echo "   Run: docker swarm init"
        return 1
    fi
    
    echo "✅ Docker Swarm is active"
    return 0
}

# read_env_value
# Reads a value from .env file.
read_env_value() {
    local env_file="$1"
    local key="$2"
    
    if [ -f "$env_file" ]; then
        grep "^${key}=" "$env_file" 2>/dev/null | cut -d'=' -f2- | tr -d '"' || echo ""
    else
        echo ""
    fi
}

# =============================================================================
# Detection Functions
# =============================================================================

# detect_existing_deployment
# Checks if a Wiki.js deployment appears to already exist.
detect_existing_deployment() {
    local env_file=".env"
    
    # Check for .env file
    if [ ! -f "$env_file" ]; then
        return 1
    fi
    
    # Check for critical variables
    local stack_name data_root
    stack_name=$(read_env_value "$env_file" "STACK_NAME")
    data_root=$(read_env_value "$env_file" "DATA_ROOT")
    
    if [ -z "$stack_name" ] || [ -z "$data_root" ]; then
        return 1
    fi
    
    # Check if stack is running in Swarm
    if docker stack ls --format '{{.Name}}' 2>/dev/null | grep -q "^${stack_name}$"; then
        return 0
    fi
    
    # Check if docker-compose.yml exists (manual deployment indicator)
    if [ -f "docker-compose.yml" ] || [ -f "swarm-stack.yml" ]; then
        return 0
    fi
    
    return 1
}

# get_deployment_info
# Gathers information about an existing deployment.
get_deployment_info() {
    local env_file=".env"
    
    echo ""
    echo "📋 Current Deployment Information"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    local stack_name data_root hostname
    stack_name=$(read_env_value "$env_file" "STACK_NAME")
    data_root=$(read_env_value "$env_file" "DATA_ROOT")
    hostname=$(read_env_value "$env_file" "WIKIJS_HOSTNAME")
    
    echo "Configuration:"
    echo "  Stack Name:    ${stack_name:-Not set}"
    echo "  Data Root:     ${data_root:-Not set}"
    echo "  Hostname:      ${hostname:-Not set}"
    echo ""
    
    if [ -n "$stack_name" ]; then
        echo "Stack Status:"
        if docker stack ls --format '{{.Name}}' 2>/dev/null | grep -q "^${stack_name}$"; then
            echo "  Status:        ✅ Running in Swarm"
            echo ""
            echo "Services:"
            docker stack ps "$stack_name" --format '  • {{.Name}} ({{.CurrentState}})' 2>/dev/null | head -5
        else
            echo "  Status:        ❌ Not running in Swarm"
        fi
    fi
    
    echo ""
}

# =============================================================================
# Menu Functions
# =============================================================================

# show_maintenance_menu
# Shows menu for existing deployments.
show_maintenance_menu() {
    while true; do
        echo ""
        echo "🛠️  Wiki.js Maintenance Menu"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        echo "1) Show deployment info"
        echo "2) Deploy / Update stack"
        echo "3) Show stack status"
        echo "4) View service logs"
        echo "5) Scale services"
        echo "6) Edit .env file"
        echo "7) Remove stack"
        echo "8) Exit"
        echo ""
        
        read_prompt "Select option (1-8): " choice
        echo ""
        
        case "$choice" in
            1) get_deployment_info ;;
            2) deploy_stack ;;
            3) show_stack_status ;;
            4) show_logs_menu ;;
            5) scale_services_menu ;;
            6) edit_env_file ;;
            7) remove_stack ;;
            8) echo "Goodbye!"; exit 0 ;;
            *) echo "❌ Invalid option" ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# show_fresh_setup_menu
# Shows menu for new deployments.
show_fresh_setup_menu() {
    echo ""
    echo "🚀 Wiki.js Fresh Setup"
    echo "━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "No existing deployment detected."
    echo ""
    
    read_prompt "Create new .env from template? (Y/n): " create_env
    if [[ ! "$create_env" =~ ^[Nn]$ ]]; then
        setup_environment
    else
        echo "Cancelled. Exiting."
        exit 0
    fi
}

# =============================================================================
# Action Functions
# =============================================================================

# setup_environment
# Sets up .env file from template.
setup_environment() {
    local template_file=".env.template"
    local env_file=".env"
    
    if [ ! -f "$template_file" ]; then
        echo "❌ Template file not found: $template_file"
        return 1
    fi
    
    if [ -f "$env_file" ]; then
        echo "⚠️  .env file already exists"
        read_prompt "Overwrite? (y/N): " overwrite
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            echo "Cancelled."
            return 1
        fi
    fi
    
    cp "$template_file" "$env_file"
    echo "✅ Created $env_file from template"
    echo ""
    echo "⚠️  IMPORTANT: Edit the following values in .env:"
    echo "   - WIKIJS_HOSTNAME (your domain)"
    echo "   - WIKIJS_DB_PASSWORD (generate a strong password)"
    echo "   - DATA_ROOT (use /swarm path, not /gluster_storage)"
    echo "   - STACK_NAME (your stack name)"
    echo ""
    
    read_prompt "Open .env in editor now? (Y/n): " open_editor
    if [[ ! "$open_editor" =~ ^[Nn]$ ]]; then
        ${EDITOR:-nano} "$env_file"
    fi
    
    echo ""
    echo "After editing .env, run this script again to deploy."
}

# deploy_stack
# Deploys or updates the Wiki.js stack.
deploy_stack() {
    local env_file=".env"
    
    if [ ! -f "$env_file" ]; then
        echo "❌ .env file not found. Run setup first."
        return 1
    fi
    
    local stack_name
    stack_name=$(read_env_value "$env_file" "STACK_NAME")
    
    if [ -z "$stack_name" ]; then
        echo "❌ STACK_NAME not set in .env"
        return 1
    fi
    
    echo "🚀 Deploying Wiki.js stack: $stack_name"
    echo ""
    
    # Check if compose file exists
    if [ -f "docker-compose.yml" ]; then
        docker stack deploy -c <(docker-compose -f docker-compose.yml config) "$stack_name"
    elif [ -f "swarm-stack.yml" ]; then
        docker stack deploy -c swarm-stack.yml "$stack_name"
    else
        # Generate from template
        if [ -f "docker-compose.yml.template" ]; then
            cp docker-compose.yml.template docker-compose.yml
            docker stack deploy -c <(docker-compose -f docker-compose.yml config) "$stack_name"
        else
            echo "❌ No compose file found"
            return 1
        fi
    fi
    
    echo ""
    echo "✅ Stack deployed successfully"
    echo ""
    echo "Wiki.js will be available at:"
    local hostname
    hostname=$(read_env_value "$env_file" "WIKIJS_HOSTNAME")
    echo "  https://$hostname"
}

# show_stack_status
# Shows current stack status.
show_stack_status() {
    local env_file=".env"
    local stack_name
    stack_name=$(read_env_value "$env_file" "STACK_NAME")
    
    if [ -z "$stack_name" ]; then
        echo "❌ STACK_NAME not set"
        return 1
    fi
    
    echo ""
    echo "Stack: $stack_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    docker stack ps "$stack_name" --format 'table {{.Name}}	{{.CurrentState}}	{{.Error}}' 2>/dev/null || echo "Stack not found"
    echo ""
    docker stack services "$stack_name" --format 'table {{.Name}}	{{.Replicas}}	{{.Image}}' 2>/dev/null || true
}

# show_logs_menu
# Shows logs for services.
show_logs_menu() {
    local env_file=".env"
    local stack_name
    stack_name=$(read_env_value "$env_file" "STACK_NAME")
    
    if [ -z "$stack_name" ]; then
        echo "❌ STACK_NAME not set"
        return 1
    fi
    
    echo ""
    echo "Service logs for $stack_name:"
    echo "1) Wiki service"
    echo "2) Database service"
    echo "3) Back"
    echo ""
    read_prompt "Select service (1-3): " service_choice
    
    case "$service_choice" in
        1) docker service logs "${stack_name}_wiki" -f --tail 100 ;;
        2) docker service logs "${stack_name}_db" -f --tail 100 ;;
        3) return ;;
        *) echo "❌ Invalid selection" ;;
    esac
}

# scale_services_menu
# Menu for scaling services.
scale_services_menu() {
    local env_file=".env"
    local stack_name
    stack_name=$(read_env_value "$env_file" "STACK_NAME")
    
    if [ -z "$stack_name" ]; then
        echo "❌ STACK_NAME not set"
        return 1
    fi
    
    echo ""
    echo "Scale services for $stack_name:"
    echo "1) Scale wiki service"
    echo "2) Scale database service (⚠️ careful!)"
    echo "3) Back"
    echo ""
    read_prompt "Select (1-3): " scale_choice
    
    case "$scale_choice" in
        1) 
            read_prompt "Enter replica count for wiki: " replicas
            docker service scale "${stack_name}_wiki=$replicas"
            ;;
        2) 
            echo "⚠️  Warning: Scaling database can cause data issues"
            read_prompt "Enter replica count for db: " replicas
            docker service scale "${stack_name}_db=$replicas"
            ;;
        3) return ;;
        *) echo "❌ Invalid selection" ;;
    esac
}

# edit_env_file
# Opens .env in editor.
edit_env_file() {
    local env_file=".env"
    
    if [ ! -f "$env_file" ]; then
        echo "❌ .env file not found"
        return 1
    fi
    
    ${EDITOR:-nano} "$env_file"
    echo "✅ .env updated"
}

# remove_stack
# Removes the stack with confirmation.
remove_stack() {
    local env_file=".env"
    local stack_name
    stack_name=$(read_env_value "$env_file" "STACK_NAME")
    
    if [ -z "$stack_name" ]; then
        echo "❌ STACK_NAME not set"
        return 1
    fi
    
    echo ""
    echo "⚠️  WARNING: This will remove the entire Wiki.js stack!"
    echo "Stack to remove: $stack_name"
    echo ""
    read_prompt "Type the stack name to confirm removal: " confirm
    
    if [ "$confirm" != "$stack_name" ]; then
        echo "❌ Confirmation failed. Stack name did not match."
        return 1
    fi
    
    echo ""
    echo "Removing stack $stack_name..."
    docker stack rm "$stack_name"
    echo ""
    echo "✅ Stack removed"
    echo "Note: Data volumes in $stack_name were NOT removed."
}

# =============================================================================
# Main Entry Point
# =============================================================================

main() {
    echo ""
    echo "📚 Wiki.js Deployment Tool"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Check Docker Swarm
    if ! check_docker_swarm; then
        exit 1
    fi
    echo ""
    
    # Detect existing deployment
    if detect_existing_deployment; then
        echo "✅ Existing Wiki.js deployment detected"
        get_deployment_info
        show_maintenance_menu
    else
        show_fresh_setup_menu
    fi
}

# Run main
main "$@"
