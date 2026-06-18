'use client'

import { useState } from "react"
import { Trash2, Plus, Save } from "lucide-react"
import { cn } from "@/lib/utils"

export type Column = {
  key: string
  label: string
  type: "text" | "number" | "date" | "time" | "textarea"
  width?: string
}

type RegisterTableProps = {
  title: string
  columns: Column[]
  initialData?: Record<string, unknown>[]
}

function generateId() {
  return Math.random().toString(36).slice(2, 10)
}

function createEmptyRow(columns: Column[], rows: Record<string, unknown>[]): Record<string, unknown> {
  const row: Record<string, unknown> = { _id: generateId() }
  for (const col of columns) {
    if (col.key === "srNo") {
      row[col.key] = rows.length + 1
    } else if (col.type === "number") {
      row[col.key] = ""
    } else {
      row[col.key] = ""
    }
  }
  return row
}

export default function RegisterTable({ title, columns, initialData = [] }: RegisterTableProps) {
  const [rows, setRows] = useState<Record<string, unknown>[]>(
    initialData.map((r, i) => ({ _id: generateId(), ...r, srNo: r.srNo ?? i + 1 }))
  )
  const [editingCell, setEditingCell] = useState<{ rowIdx: number; key: string } | null>(null)

  function addRow() {
    setRows((prev) => [...prev, createEmptyRow(columns, prev)])
  }

  function deleteRow(idx: number) {
    setRows((prev) => {
      const next = prev.filter((_, i) => i !== idx)
      return next.map((row, i) => {
        const hasSrNo = columns.some((c) => c.key === "srNo")
        if (hasSrNo) return { ...row, srNo: i + 1 }
        return row
      })
    })
  }

  function updateCell(idx: number, key: string, value: string) {
    setRows((prev) =>
      prev.map((row, i) => (i === idx ? { ...row, [key]: value } : row))
    )
  }

  function handleSave() {
    console.log(`[${title}] Saved data:`, rows)
  }

  return (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200">
      <div className="flex items-center justify-between px-4 py-3 border-b border-gray-200">
        <div className="flex items-center gap-3">
          <h2 className="text-base font-semibold text-slate-800">{title}</h2>
          <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-blue-50 text-blue-700 border border-blue-100">
            {rows.length} {rows.length === 1 ? "row" : "rows"}
          </span>
        </div>
        <button
          onClick={handleSave}
          className="flex items-center gap-1.5 px-3 py-1.5 text-sm bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors font-medium"
        >
          <Save className="w-4 h-4" />
          Save
        </button>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="sticky top-0 z-10">
            <tr className="bg-slate-100">
              {columns.map((col) => (
                <th
                  key={col.key}
                  className="text-left px-3 py-2 text-slate-600 text-xs uppercase font-semibold whitespace-nowrap border-b border-gray-200"
                  style={col.width ? { minWidth: col.width } : undefined}
                >
                  {col.label}
                </th>
              ))}
              <th className="px-3 py-2 text-slate-600 text-xs uppercase font-semibold border-b border-gray-200 w-10"></th>
            </tr>
          </thead>
          <tbody>
            {rows.length === 0 && (
              <tr>
                <td
                  colSpan={columns.length + 1}
                  className="px-3 py-8 text-center text-slate-400 text-sm"
                >
                  No entries yet. Click &ldquo;Add Row&rdquo; to begin.
                </td>
              </tr>
            )}
            {rows.map((row, rowIdx) => (
              <tr
                key={String(row._id)}
                className={cn(
                  "border-b border-gray-100 hover:bg-gray-50 transition-colors",
                  rowIdx % 2 === 0 ? "bg-white" : "bg-gray-50/30"
                )}
              >
                {columns.map((col) => {
                  const isEditing =
                    editingCell?.rowIdx === rowIdx && editingCell?.key === col.key
                  const value = row[col.key] as string ?? ""
                  const isReadOnly = col.key === "srNo"

                  return (
                    <td
                      key={col.key}
                      className="px-3 py-2 align-top"
                      style={col.width ? { minWidth: col.width } : undefined}
                      onClick={() => {
                        if (!isReadOnly) setEditingCell({ rowIdx, key: col.key })
                      }}
                    >
                      {isReadOnly ? (
                        <span className="text-slate-500 text-xs">{value}</span>
                      ) : isEditing ? (
                        col.type === "textarea" ? (
                          <textarea
                            autoFocus
                            value={value}
                            onChange={(e) => updateCell(rowIdx, col.key, e.target.value)}
                            onBlur={() => setEditingCell(null)}
                            className="w-full min-w-[160px] border border-blue-400 rounded px-2 py-1 text-sm focus:outline-none focus:ring-1 focus:ring-blue-500 resize-none"
                            rows={3}
                          />
                        ) : (
                          <input
                            autoFocus
                            type={col.type}
                            value={value}
                            onChange={(e) => updateCell(rowIdx, col.key, e.target.value)}
                            onBlur={() => setEditingCell(null)}
                            className="w-full min-w-[100px] border border-blue-400 rounded px-2 py-1 text-sm focus:outline-none focus:ring-1 focus:ring-blue-500"
                          />
                        )
                      ) : (
                        <span
                          className={cn(
                            "block cursor-text min-h-[24px] min-w-[80px]",
                            !value && "text-slate-300 text-xs italic"
                          )}
                        >
                          {value || "—"}
                        </span>
                      )}
                    </td>
                  )
                })}
                <td className="px-2 py-2 text-center align-top">
                  <button
                    onClick={() => deleteRow(rowIdx)}
                    className="text-slate-300 hover:text-red-500 transition-colors p-1 rounded"
                    title="Delete row"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="px-4 py-3 border-t border-gray-100">
        <button
          onClick={addRow}
          className="flex items-center gap-1.5 px-3 py-1.5 text-sm text-blue-600 border border-blue-300 rounded-md hover:bg-blue-50 transition-colors font-medium"
        >
          <Plus className="w-4 h-4" />
          Add Row
        </button>
      </div>
    </div>
  )
}
