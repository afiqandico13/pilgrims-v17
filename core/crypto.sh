#!/bin/bash
encrypt_scan() {
    local dir=$1 pass=$2 out="${dir}.enc"
    tar czf "${dir}.tar.gz" -C "$(dirname "$dir")" "$(basename "$dir")" 2>/dev/null
    openssl enc -aes-256-cbc -salt -pbkdf2 -iter 100000 -in "${dir}.tar.gz" -out "$out" -pass pass:"$pass" 2>/dev/null
    rm -f "${dir}.tar.gz"
    [ -f "$out" ] && print_success "Encrypted: $out" || print_error "Encryption failed"
}
decrypt_scan() {
    local file=$1 pass=$2 out="${file%.enc}.tar.gz"
    openssl enc -aes-256-cbc -d -pbkdf2 -iter 100000 -in "$file" -out "$out" -pass pass:"$pass" 2>/dev/null
    tar xzf "$out" -C "$(dirname "$file")" 2>/dev/null && rm -f "$out"
    [ -d "${file%.enc}" ] && print_success "Decrypted: ${file%.enc}" || print_error "Decryption failed (wrong password?)"
}
