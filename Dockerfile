FROM dockurr/windows:latest

# Default environment variables (override via Railway Variables)
ENV VERSION="2022" \
    USERNAME="Mpragans" \
    PASSWORD="123456" \
    RAM_SIZE="16G" \
    CPU_CORES="8" \
    DISK_SIZE="900G" \
    REGION="id-ID" \
    KEYBOARD="id-ID" \
    KVM="N"

# Ensure storage folder exists
RUN mkdir -p /storage

# Expose the Dockur web viewer port
EXPOSE 8006
