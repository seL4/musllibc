#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <filesystem>

namespace fs = std::filesystem;

// This should be in sync with what's in dynlink.c
struct CachedRelocInfo {
    int type;           // Type of the relocation
    size_t st_value;    // Symbol value
    size_t offset;      // Offset of the relocation
    char dso_name[255]; // Name of the DSO
};

std::vector<CachedRelocInfo> read_cached_relocs(const std::string& filename) {
    std::ifstream file(filename, std::ios::binary);
    if (!file) {
        std::cerr << "Failed to open file: " << filename << '\n';
        return {};
    }

    size_t file_size = fs::file_size(filename);

    std::vector<char> buffer(file_size);
    if (!file.read(buffer.data(), file_size)) {
        std::cerr << "Failed to read file: " << filename << '\n';
        return {};
    }

    size_t count = file_size / sizeof(CachedRelocInfo);
    auto* relocs = reinterpret_cast<CachedRelocInfo*>(buffer.data());

    // Convert fixed-length char arrays to std::string
    return std::vector<CachedRelocInfo>(relocs, relocs + count);
}

void print_reloc_info(const CachedRelocInfo& reloc) {
    std::cout << "Type: " << reloc.type << ", "
              << "Symbol Value: " << reloc.st_value << ", "
              << "Offset: " << reloc.offset << ", "
              << "DSO Name: " << reloc.dso_name << '\n';
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " <filename>\n";
        return 1;
    }

    std::string filename = argv[1];

    if (!fs::exists(filename)) {
        std::cerr << "File does not exist: " << filename << '\n';
        return 1;
    }

    auto relocs = read_cached_relocs(filename);

    if (relocs.empty()) {
        std::cerr << "No cached relocation information found.\n";
        return 1;
    }

    std::cout << "Cached Relocation Information:\n";
    for (const auto& reloc : relocs) {
        print_reloc_info(reloc);
    }

    return 0;
}