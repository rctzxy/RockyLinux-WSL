#include "stdafx.h"

namespace Systemd
{

    // Appends text to file in the distro. Returns a success boolean.
    bool AppendToFile(std::wstring const& text, std::filesystem::path const& file)
    {
        const auto command = concat(L"printf ", std::quoted(text), L" >> ", file);
        DWORD exitCode;
        const HRESULT hr = g_pWslApi->WslLaunchInteractive(command.c_str(), FALSE, &exitCode);
        return SUCCEEDED(hr) && exitCode == 0;
    }

    // Calls mkdir. Returns a success boolean.
    bool Mkdir(std::wstring_view flags, std::filesystem::path const& linux_path)
    {
        const auto command = concat(L"mkdir ", flags, L" ", linux_path);
        DWORD exitCode;
        const HRESULT hr = g_pWslApi->WslLaunchInteractive(command.c_str(), FALSE, &exitCode);
        return SUCCEEDED(hr) && exitCode == 0;
    }

    // Enables or disables systemd in config file
    bool EnableSystemd()
    {
        const std::filesystem::path wsl_conf{L"/etc/wsl.conf"};
        return AppendToFile(L"\n[boot]\nsystemd=true\n", wsl_conf);
    }


    void Configure(const bool enable)
    {
        if (!enable) {
            return;
        }

        if (!EnableSystemd()) {
            return;
        }

        AppendToFile(L"\naction=reboot\n", L"/run/launcher-command");
    }
}
