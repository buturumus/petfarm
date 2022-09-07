# variables.tf

variable "admin_name" {
  type = string
  default = "xxx"
}

variable "admin_pw" {
  type = string
  default = "ChiiH0aaA-z_"
}

variable "install_spec_soft" {
  type = string
  default = "${
    "&& apt -y install vim git python3-pip aptitude docker.io vnstat wget "   }${
    "&& cd /home/xxx && git clone https://github.com/MHProDev/MHDDoS.git "    }${
    "&& mv MHDDoS mh && cd /home/xxx/mh "                                     }${
    "&& sudo -u xxx pip install -r /home/xxx/mh/requirements.txt "            }${
    "&& mkdir /home/xxx/db1000 && VERS=v[0-9.]+ "                             }${
    "&& wget -O /home/xxx/db1000/db1000.tar.gz "                              }${
      "https://github.com/arriven/db1000n/releases/download/`"                }${
        "wget --spider https://github.com/arriven/db1000n/releases/latest "   }${
        "2>&1 | grep Location | grep -oE $VERS"                               }${
      "`/db1000n_linux_amd64.tar.gz"                                          }${
    "&& cd /home/xxx/db1000 && tar -zxvf db1000.tar.gz"                       }${
    "&& docker pull ghcr.io/opengs/uashield:master "                          }${
    ""
  }"
}

