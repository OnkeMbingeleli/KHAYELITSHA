import { useEffect, useRef } from "react";
import QRCode from "qrcode";

type Props = {
  data: string;
  ownerCode: string;
  plate: string;
  routeName: string;
  seats: number;
  size?: number;
};

/** Round LAGUNYA sticker with QR in the middle and "LAGUNYA" curved around the edge. */
export function LagunyaSticker({ data, ownerCode, plate, routeName, seats, size = 280 }: Props) {
  const qrRef = useRef<HTMLImageElement>(null);

  useEffect(() => {
    QRCode.toDataURL(data, { errorCorrectionLevel: "H", margin: 1, width: 200 }).then((url) => {
      if (qrRef.current) qrRef.current.src = url;
    });
  }, [data]);

  const r = size / 2;
  // path for top arc curve
  const arcRadius = r - 14;
  return (
    <div
      className="relative bg-card text-foreground rounded-full border-4 border-primary shadow-xl flex items-center justify-center select-none"
      style={{ width: size, height: size }}
    >
      <svg width={size} height={size} className="absolute inset-0 pointer-events-none">
        <defs>
          <path id="lagunya-arc-top" d={`M ${r - arcRadius},${r} a ${arcRadius},${arcRadius} 0 0,1 ${arcRadius * 2},0`} fill="none" />
          <path id="lagunya-arc-bottom" d={`M ${r + arcRadius},${r} a ${arcRadius},${arcRadius} 0 0,1 -${arcRadius * 2},0`} fill="none" />
        </defs>
        <text fill="currentColor" fontSize={size * 0.075} fontWeight={700} letterSpacing={size * 0.025}>
          <textPath href="#lagunya-arc-top" startOffset="50%" textAnchor="middle">L A G U N Y A</textPath>
        </text>
        <text fill="currentColor" fontSize={size * 0.05} letterSpacing={size * 0.012}>
          <textPath href="#lagunya-arc-bottom" startOffset="50%" textAnchor="middle">{routeName.toUpperCase()} · {seats} SEATS</textPath>
        </text>
      </svg>
      <div className="flex flex-col items-center gap-1" style={{ width: size * 0.55 }}>
        <img ref={qrRef} alt="QR" className="rounded bg-white p-1" style={{ width: size * 0.45, height: size * 0.45 }} />
        <p className="font-mono font-bold text-sm">{plate}</p>
        <p className="text-[10px] text-muted-foreground">{ownerCode}</p>
      </div>
    </div>
  );
}