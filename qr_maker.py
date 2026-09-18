#!/usr/bin/env python3
"""
qr_maker.py — gera QR codes a partir de URL, texto, WhatsApp ou e-mail,
com opção de personalizar inserindo um ícone/logo no centro da imagem.

Uso:
    python3 qr_maker.py "https://exemplo.com" -o qr_url.png
    python3 qr_maker.py "texto qualquer" -o qr_texto.png
    python3 qr_maker.py "+55 11 99999-9999" -o qr_whats.png
    python3 qr_maker.py "fulano@exemplo.com" -o qr_email.png
    python3 qr_maker.py "https://exemplo.com" -o qr_logo.png --icon logo.png

Dependências:
    pip install qrcode[pil] pillow
"""

import argparse
import re
import sys
from urllib.parse import quote

try:
    import qrcode
    from PIL import Image
except ImportError as exc:
    sys.exit(f"Faltando dependência: {exc.name}. Execute: pip install qrcode[pil] pillow")


# --------------------------------------------------------------------------
# Detecção automática do objetivo
# --------------------------------------------------------------------------

EMAIL_RE = re.compile(r"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$")
PHONE_RE = re.compile(r"^\+?[\d\s().-]{7,}$")


def sanitize_phone(number: str) -> str:
    """Remove tudo que não for dígito; mantém o '+' inicial se presente."""
    return re.sub(r"\D", "", number)


def build_content(data: str, force: str | None = None, message: str | None = None) -> tuple[str, str]:
    """Decide o conteúdo codificado e o objetivo, ou usa a força manual.

    Retorna (conteúdo_do_qr, objetivo).
    """
    if force == "whatsapp":
        url = f"https://wa.me/{sanitize_phone(data)}"
        if message:
            url += f"?text={quote(message)}"
        return url, "whatsapp"
    if force == "email":
        return f"mailto:{data.strip()}", "email"
    if force == "url":
        return data.strip(), "url"
    if force == "text":
        return data, "text"

    stripped = data.strip()
    if EMAIL_RE.match(stripped):
        return f"mailto:{stripped}", "email"
    if PHONE_RE.match(stripped):
        url = f"https://wa.me/{sanitize_phone(stripped)}"
        if message:
            url += f"?text={quote(message)}"
        return url, "whatsapp"
    if stripped.startswith(("http://", "https://")):
        return stripped, "url"
    return data, "text"


# --------------------------------------------------------------------------
# Geração do QR
# --------------------------------------------------------------------------

def make_qr(
    content: str,
    output: str,
    icon: str | None = None,
    box_size: int = 10,
    border: int = 4,
    fill_color: str = "#000000",
    back_color: str = "#FFFFFF",
    icon_scale: float = 0.22,
) -> str:
    """Gera o QR code e opcionalmente insere um ícone centralizado."""
    qr = qrcode.QRCode(
        error_correction=qrcode.constants.ERROR_CORRECT_H,
        box_size=box_size,
        border=border,
    )
    qr.add_data(content)
    qr.make(fit=True)

    img = qr.make_image(fill_color=fill_color, back_color=back_color).convert("RGB")

    if icon:
        logo = Image.open(icon).convert("RGB")
        icon_size = int(img.size[0] * icon_scale)
        logo.thumbnail((icon_size, icon_size))

        # Caixa branca ao redor do ícone para não quebrar a leitura do QR
        pad = max(int(icon_size * 0.08), 4)
        box = Image.new("RGB", (logo.width + pad * 2, logo.height + pad * 2), back_color)
        box.paste(logo, (pad, pad))

        x = (img.size[0] - box.width) // 2
        y = (img.size[1] - box.height) // 2
        img.paste(box, (x, y))

    img.save(output)
    return output


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Gera QR code a partir de URL, texto, WhatsApp ou e-mail, "
        "com ícone central opcional.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("data", help="URL, texto, telefone (WhatsApp) ou e-mail")
    parser.add_argument("-o", "--output", default="qr_code.png", help="Arquivo de saída (padrão: qr_code.png)")
    parser.add_argument("--icon", default=None, help="Caminho do ícone/logo para inserir no centro")
    parser.add_argument("--message", default=None,
                        help="Mensagem CTA pré-preenchida (WhatsApp/e-mail) embutida no QR")
    parser.add_argument("--type", choices=["url", "whatsapp", "email", "text"], default=None,
                        help="Força o tipo/objetivo (se omitido, é detectado automaticamente)")
    parser.add_argument("--box-size", type=int, default=10, help="Tamanho de cada módulo em px (padrão: 10)")
    parser.add_argument("--border", type=int, default=4, help="Espessura da borda (padrão: 4)")
    parser.add_argument("--fg", default="#000000", help="Cor do QR (padrão: #000000)")
    parser.add_argument("--bg", default="#FFFFFF", help="Cor de fundo (padrão: #FFFFFF)")
    parser.add_argument("--icon-scale", type=float, default=0.22,
                        help="Fração da imagem que o ícone ocupa (padrão: 0.22)")

    args = parser.parse_args()

    content, objective = build_content(args.data, args.type, args.message)

    if objective == "whatsapp":
        print(f"[WhatsApp] QR aponta para: {content}")
    elif objective == "email":
        print(f"[E-mail]   QR aponta para: {content}")
    elif objective == "url":
        print(f"[URL]      QR aponta para: {content}")
    else:
        print(f"[Texto]    QR contém: {content[:80]}")

    make_qr(
        content=content,
        output=args.output,
        icon=args.icon,
        box_size=args.box_size,
        border=args.border,
        fill_color=args.fg,
        back_color=args.bg,
        icon_scale=args.icon_scale,
    )
    print(f"QR gerado em: {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())