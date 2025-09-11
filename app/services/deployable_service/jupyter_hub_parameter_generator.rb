# frozen_string_literal: true

class DeployableService::JupyterHubParameterGenerator
  # Generate hardcoded parameters matching jupyterhub_datamount.yml TOSCA template
  def self.generate_parameters
    [
      # Frontend Resources
      Parameter::Select.new(
        id: "fe_cpus",
        name: "Frontend CPU Cores",
        hint: "Number of CPUs for the frontend node",
        values: [2, 4, 8, 16],
        value_type: "integer",
        mode: "dropdown"
      ),
      Parameter::Select.new(
        id: "fe_mem",
        name: "Frontend Memory",
        hint: "Amount of memory for the frontend node",
        values: ["4 GiB", "8 GiB", "16 GiB", "32 GiB"],
        value_type: "string",
        mode: "dropdown"
      ),
      Parameter::Select.new(
        id: "fe_disk_size",
        name: "Frontend Disk Size",
        hint: "Size of disk for frontend node",
        values: ["50 GiB", "100 GiB", "200 GiB", "500 GiB"],
        value_type: "string",
        mode: "dropdown"
      ),
      # Worker Configuration
      Parameter::Select.new(
        id: "wn_num",
        name: "Number of Worker Nodes",
        hint: "Number of worker nodes in cluster",
        values: [1, 2, 3, 4, 5],
        value_type: "integer",
        mode: "dropdown"
      ),
      Parameter::Select.new(
        id: "wn_cpus",
        name: "Worker Node CPUs",
        hint: "CPU cores per worker node",
        values: [2, 4, 8, 16],
        value_type: "integer",
        mode: "dropdown"
      ),
      Parameter::Select.new(
        id: "wn_mem",
        name: "Worker Node Memory",
        hint: "Memory per worker node",
        values: ["4 GiB", "8 GiB", "16 GiB", "32 GiB"],
        value_type: "string",
        mode: "dropdown"
      ),
      Parameter::Select.new(
        id: "wn_disk_size",
        name: "Worker Node Disk",
        hint: "Root disk size for worker nodes",
        values: ["20 GiB", "50 GiB", "100 GiB", "200 GiB"],
        value_type: "string",
        mode: "dropdown"
      ),
      # Configuration
      Parameter::Input.new(
        id: "kube_public_dns_name",
        name: "Public DNS Hostname",
        hint: "DNS name for JupyterHub access",
        value_type: "string"
      ),
      Parameter::Input.new(
        id: "admin_password",
        name: "JupyterHub Admin Password",
        hint: "Password for JupyterHub administrator user",
        value_type: "string"
      ),
      # Dataset List - Text area for DOI list
      Parameter::Input.new(
        id: "dataset_ids",
        name: "Dataset DOI List",
        hint: "Comma-separated list of dataset DOIs to mount",
        value_type: "string"
      )
    ]
  end
end
