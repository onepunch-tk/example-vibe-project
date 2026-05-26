"use client";

import { useEffect, useState } from "react";

type Step = {
  label: string;
  detail: string;
  more: string;
};

const STEPS: Step[] = [
  {
    label: "1. 프롬프트",
    detail: "사용자가 자연어로 의도 전달",
    more: "사람이 목표를 자연어로 던지면 사이클이 시작됩니다. 명확한 의도일수록 이후 단계의 제안 품질이 올라갑니다.",
  },
  {
    label: "2. 컨텍스트 수집",
    detail: "CLAUDE.md · 파일 · 도구 출력 읽기",
    more: "에이전트가 CLAUDE.md, 관련 파일, 이전 도구 출력을 읽어 현재 상태를 파악합니다. 여기서 모인 정보가 제안의 토대가 됩니다.",
  },
  {
    label: "3. 변경 제안",
    detail: "diff 또는 명령 형태로 제시",
    more: "수집한 컨텍스트를 바탕으로 코드 diff나 실행할 명령을 구체적으로 만들어 냅니다. 아직 적용 전이라 되돌릴 수 있는 단계입니다.",
  },
  {
    label: "4. 권한 요청",
    detail: "Allow / Ask / Deny 정책에 따라",
    more: "제안을 실제로 적용하기 전에 권한 정책에 따라 사람의 승인을 받습니다. 사람이 흐름에 개입할 수 있는 유일한 관문입니다.",
  },
  {
    label: "5. 실행",
    detail: "도구 호출 또는 파일 쓰기",
    more: "승인된 제안을 도구 호출이나 파일 쓰기로 실제 적용합니다. 이 단계에서 비로소 시스템 상태가 바뀝니다.",
  },
  {
    label: "6. 결과 관찰",
    detail: "에러·테스트·로그를 다시 컨텍스트로",
    more: "실행 결과인 에러·테스트·로그를 다시 읽어 다음 사이클의 컨텍스트로 넣습니다. 이 되먹임이 self-correction 루프를 닫습니다.",
  },
];

export function LoopDiagram() {
  const radius = 150;
  const cx = 200;
  const cy = 200;

  const [active, setActive] = useState<number | null>(null);

  useEffect(() => {
    function onKeyDown(e: KeyboardEvent) {
      if (e.key === "Escape") {
        setActive(null);
        if (document.activeElement instanceof HTMLElement) {
          document.activeElement.blur();
        }
      }
    }
    document.addEventListener("keydown", onKeyDown);
    return () => document.removeEventListener("keydown", onKeyDown);
  }, []);

  const positions = STEPS.map((_, i) => {
    const angle = (i / STEPS.length) * Math.PI * 2 - Math.PI / 2;
    return {
      x: cx + Math.cos(angle) * radius,
      y: cy + Math.sin(angle) * radius,
    };
  });

  return (
    <div className="grid items-center gap-10 md:grid-cols-[400px_1fr]">
      <div className="relative mx-auto w-full max-w-[400px]">
        <svg
          viewBox="0 0 400 400"
          className="w-full"
          role="img"
          aria-label="에이전트 루프 다이어그램"
        >
          <defs>
            <linearGradient id="ring" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0%" stopColor="#a855f7" stopOpacity="0.7" />
              <stop offset="100%" stopColor="#06b6d4" stopOpacity="0.7" />
            </linearGradient>
            <marker
              id="arrow"
              viewBox="0 0 10 10"
              refX="8"
              refY="5"
              markerWidth="6"
              markerHeight="6"
              orient="auto-start-reverse"
            >
              <path d="M 0 0 L 10 5 L 0 10 z" fill="#06b6d4" />
            </marker>
          </defs>
          <circle
            cx={cx}
            cy={cy}
            r={radius}
            fill="none"
            stroke="url(#ring)"
            strokeWidth="1.5"
            strokeDasharray="6 4"
          />
          {positions.map((_, i) => {
            const next = positions[(i + 1) % positions.length];
            const midAngle =
              ((i + 0.5) / STEPS.length) * Math.PI * 2 - Math.PI / 2;
            const arcRadius = radius;
            const sx = cx + Math.cos(midAngle - 0.3) * arcRadius;
            const sy = cy + Math.sin(midAngle - 0.3) * arcRadius;
            const ex = cx + Math.cos(midAngle + 0.3) * arcRadius;
            const ey = cy + Math.sin(midAngle + 0.3) * arcRadius;
            return (
              <path
                key={`arc-${i}`}
                d={`M ${sx} ${sy} A ${arcRadius} ${arcRadius} 0 0 1 ${ex} ${ey}`}
                fill="none"
                stroke="#06b6d4"
                strokeWidth="1.5"
                markerEnd="url(#arrow)"
                opacity="0.7"
                style={{
                  ...(next ? {} : {}),
                }}
              />
            );
          })}
          {positions.map((p, i) => (
            <g
              key={`node-${i}`}
              tabIndex={0}
              role="button"
              aria-label={STEPS[i].label}
              className="cursor-pointer outline-none"
              onMouseEnter={() => setActive(i)}
              onMouseLeave={() => setActive(null)}
              onFocus={() => setActive(i)}
              onBlur={() => setActive(null)}
            >
              <circle
                cx={p.x}
                cy={p.y}
                r="28"
                fill="#11111a"
                stroke={active === i ? "#06b6d4" : "#a855f7"}
                strokeWidth={active === i ? "3" : "1.5"}
              />
              <text
                x={p.x}
                y={p.y + 4}
                textAnchor="middle"
                fill="#e7e7f0"
                fontSize="13"
                fontWeight="600"
              >
                {i + 1}
              </text>
            </g>
          ))}
          <text
            x={cx}
            y={cy - 8}
            textAnchor="middle"
            fill="#9897a8"
            fontSize="11"
          >
            Agent Loop
          </text>
          <text
            x={cx}
            y={cy + 12}
            textAnchor="middle"
            fill="#e7e7f0"
            fontSize="14"
            fontWeight="600"
          >
            반복 사이클
          </text>
        </svg>

        {active !== null && (
          <div
            role="tooltip"
            className="surface pointer-events-none absolute z-10 w-max max-w-[220px] px-3 py-2"
            style={{
              left: `${(positions[active].x / 400) * 100}%`,
              top: `${(positions[active].y / 400) * 100}%`,
              transform: "translate(-50%, -100%)",
              marginTop: "-12px",
            }}
          >
            <p className="text-xs font-semibold text-[var(--color-fg)]">
              {STEPS[active].label}
            </p>
            <p className="mt-1 text-xs leading-relaxed text-[var(--color-muted)]">
              {STEPS[active].more}
            </p>
          </div>
        )}
      </div>

      <ol className="space-y-3">
        {STEPS.map((step, i) => (
          <li
            key={step.label}
            className={`surface px-4 py-3 ${
              active === i ? "border-[var(--color-fg)]" : ""
            }`}
          >
            <p className="text-sm font-semibold">{step.label}</p>
            <p className="text-xs text-[var(--color-muted)]">{step.detail}</p>
          </li>
        ))}
      </ol>
    </div>
  );
}
