#include <openssl/sha.h>
#include <stdio.h>
#include <string.h>

void hash_pin(const char *pin, const char *salt, char *output)
{
    unsigned char hash[SHA256_DIGEST_LENGTH];
    char input[256];

    snprintf(input, sizeof(input), "%s%s", pin, salt);

    SHA256(
        (unsigned char *)input,
        strlen(input),
        hash
    );

    for (int i = 0; i < SHA256_DIGEST_LENGTH; i++) {
        sprintf(output + (i * 2), "%02x", hash[i]);
    }

    output[64] = '\0';
}