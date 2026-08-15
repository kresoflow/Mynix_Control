from typing import Optional

def format_selected_options(selected_options: Optional[dict]) -> Optional[str]:
    """
    Format item variation and modifiers into a single readable string.
    e.g. '0.5л, Сырный соус, Халапеньо'
    """
    if not selected_options or not isinstance(selected_options, dict):
        return None

    parts = []
    if "variation" in selected_options and selected_options["variation"]:
        parts.append(str(selected_options["variation"]))

    if "modifiers" in selected_options and isinstance(selected_options["modifiers"], list):
        for m in selected_options["modifiers"]:
            if isinstance(m, dict) and "name" in m and m["name"]:
                parts.append(str(m["name"]))
            elif isinstance(m, str) and m:
                parts.append(m)

    return ", ".join(parts) if parts else None
