#include <stdio.h>

void hash_pin(
    const char *pin,
    const char *salt,
    char *output
);

int main(void)
{
    char output[65];

    hash_pin(
        "1234",
        "STADIUM2026SALT",
        output
    );

    printf("Hash: %s\n", output);

    return 0;
}