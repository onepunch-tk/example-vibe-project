import { describe, it, expect } from "vitest";
import { createElement } from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { LoopDiagram } from "@/components/LoopDiagram";

// LoopDiagram은 훅을 쓰는 클라이언트 컴포넌트이므로 React 렌더 사이클을 통해
// 마운트해야 한다. 파일이 .ts라 JSX를 못 쓰므로 createElement로 렌더한다.
const renderDiagram = () => render(createElement(LoopDiagram));

const STEP_LABELS = [
  "1. 프롬프트",
  "2. 컨텍스트 수집",
  "3. 변경 제안",
  "4. 권한 요청",
  "5. 실행",
  "6. 결과 관찰",
];

describe("LoopDiagram", () => {
  it("6개 단계 노드가 role=button과 aria-label로 렌더되고 오른쪽 리스트에도 6개 라벨이 보인다", () => {
    renderDiagram();

    const buttons = screen.getAllByRole("button");
    expect(buttons).toHaveLength(6);

    for (const label of STEP_LABELS) {
      expect(screen.getByRole("button", { name: label })).toBeDefined();
      // 오른쪽 ol 리스트에도 라벨 텍스트가 보여야 한다
      expect(screen.getAllByText(label).length).toBeGreaterThanOrEqual(1);
    }
  });

  it("노드에 mouseEnter 하면 tooltip이 나타나고 mouseLeave 하면 사라진다", () => {
    renderDiagram();

    const firstNode = screen.getByRole("button", { name: STEP_LABELS[0] });

    fireEvent.mouseEnter(firstNode);
    const tooltip = screen.getByRole("tooltip");
    expect(tooltip).toBeDefined();
    // tooltip 안에 해당 단계 관련 설명 텍스트가 일부라도 있어야 한다
    expect(tooltip.textContent).not.toBe("");

    fireEvent.mouseLeave(firstNode);
    expect(screen.queryByRole("tooltip")).toBeNull();
  });

  it("노드에 focus 하면 tooltip이 나타난다", () => {
    renderDiagram();

    const thirdNode = screen.getByRole("button", { name: STEP_LABELS[2] });

    fireEvent.focus(thirdNode);
    expect(screen.getByRole("tooltip")).toBeDefined();
  });

  it("tooltip이 열린 상태에서 Escape 키를 누르면 tooltip이 사라진다", () => {
    renderDiagram();

    const secondNode = screen.getByRole("button", { name: STEP_LABELS[1] });
    fireEvent.mouseEnter(secondNode);
    expect(screen.getByRole("tooltip")).toBeDefined();

    fireEvent.keyDown(document, { key: "Escape" });
    expect(screen.queryByRole("tooltip")).toBeNull();
  });
});
