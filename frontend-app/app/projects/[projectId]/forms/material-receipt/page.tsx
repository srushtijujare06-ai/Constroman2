'use client'

import { useState } from "react"
import { useParams } from "next/navigation"
import { Plus, Trash2, Save } from "lucide-react"
import Header from "@/components/layout/Header"
import { materialReceiptEntries, projects } from "@/lib/mock-data"
import type { MaterialReceiptEntry } from "@/lib/types"

function generateId() {
  return Math.random().toString(36).slice(2, 10)
}

function emptyRow(rows: MaterialReceiptEntry[]): MaterialReceiptEntry {
  return {
    id: generateId(),
    srNo: rows.length + 1,
    date: "",
    timeIn: "",
    poNo: "",
    grnNo: "",
    materialDescription: "",
    unit: "",
    supplier: "",
    quantityReceived: 0,
    quantityRejected: 0,
    quantityAccepted: 0,
    remarks: "",
  }
}

export default function MaterialReceiptPage() {
  const params = useParams<{ projectId: string }>()
  const projectId = params.projectId
  const project = projects.find((p) => p.id === projectId)
  const initial = materialReceiptEntries[projectId] ?? []

  const [rows, setRows] = useState<MaterialReceiptEntry[]>(
    initial.map((r, i) => ({ ...r, srNo: i + 1 }))
  )

  function addRow() {
    setRows((prev) => [...prev, emptyRow(prev)])
  }

  function deleteRow(idx: number) {
    setRows((prev) => prev.filter((_, i) => i !== idx).map((r, i) => ({ ...r, srNo: i + 1 })))
  }

  function update<K extends keyof MaterialReceiptEntry>(idx: number, key: K, value: MaterialReceiptEntry[K]) {
    setRows((prev) =>
      prev.map((row, i) => {
        if (i !== idx) return row
        const updated = { ...row, [key]: value }
        if (key === "quantityReceived" || key === "quantityRejected") {
          updated.quantityAccepted = (Number(updated.quantityReceived) || 0) - (Number(updated.quantityRejected) || 0)
        }
        return updated
      })
    )
  }

  function handleSave() {
    console.log("[Material Receipt] Saved:", rows)
  }

  const thClass = "text-left px-3 py-2 text-slate-600 text-xs uppercase font-semibold whitespace-nowrap border-b border-gray-200"
  const tdClass = "px-2 py-1.5 align-top"
  const cellInput = "border border-gray-200 rounded px-1.5 py-1 text-xs focus:outline-none focus:ring-1 focus:ring-blue-500 w-full"

  return (
    <div className="min-h-full bg-gray-50">
      <Header title="Material Receipt Register" subtitle={project?.name ?? projectId} />
      <div className="p-6">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="flex items-center justify-between px-4 py-3 border-b border-gray-200">
            <div className="flex items-center gap-3">
              <h2 className="text-base font-semibold text-slate-800">Material Receipt Register</h2>
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
                  <th className={thClass} style={{ minWidth: 60 }}>Sr. No</th>
                  <th className={thClass} style={{ minWidth: 120 }}>Date</th>
                  <th className={thClass} style={{ minWidth: 100 }}>Time In</th>
                  <th className={thClass} style={{ minWidth: 130 }}>PO No</th>
                  <th className={thClass} style={{ minWidth: 120 }}>GRN No</th>
                  <th className={thClass} style={{ minWidth: 200 }}>Material Description</th>
                  <th className={thClass} style={{ minWidth: 80 }}>Unit</th>
                  <th className={thClass} style={{ minWidth: 180 }}>Supplier</th>
                  <th className={thClass} style={{ minWidth: 110 }}>Qty Received</th>
                  <th className={thClass} style={{ minWidth: 110 }}>Qty Rejected</th>
                  <th className={thClass} style={{ minWidth: 110 }}>Qty Accepted</th>
                  <th className={thClass} style={{ minWidth: 160 }}>Remarks</th>
                  <th className={thClass} style={{ width: 40 }}></th>
                </tr>
              </thead>
              <tbody>
                {rows.length === 0 && (
                  <tr>
                    <td colSpan={13} className="px-3 py-8 text-center text-slate-400 text-sm">
                      No entries yet. Click &ldquo;Add Row&rdquo; to begin.
                    </td>
                  </tr>
                )}
                {rows.map((row, idx) => (
                  <tr key={row.id} className="border-b border-gray-100 hover:bg-gray-50">
                    <td className={tdClass}>
                      <span className="text-slate-500 text-xs px-1">{row.srNo}</span>
                    </td>
                    <td className={tdClass}>
                      <input type="date" value={row.date} onChange={(e) => update(idx, "date", e.target.value)} className={cellInput} style={{ minWidth: 120 }} />
                    </td>
                    <td className={tdClass}>
                      <input type="time" value={row.timeIn} onChange={(e) => update(idx, "timeIn", e.target.value)} className={cellInput} style={{ minWidth: 90 }} />
                    </td>
                    <td className={tdClass}>
                      <input type="text" value={row.poNo} onChange={(e) => update(idx, "poNo", e.target.value)} className={cellInput} />
                    </td>
                    <td className={tdClass}>
                      <input type="text" value={row.grnNo} onChange={(e) => update(idx, "grnNo", e.target.value)} className={cellInput} />
                    </td>
                    <td className={tdClass}>
                      <input type="text" value={row.materialDescription} onChange={(e) => update(idx, "materialDescription", e.target.value)} className={cellInput} />
                    </td>
                    <td className={tdClass}>
                      <input type="text" value={row.unit} onChange={(e) => update(idx, "unit", e.target.value)} className={cellInput} />
                    </td>
                    <td className={tdClass}>
                      <input type="text" value={row.supplier} onChange={(e) => update(idx, "supplier", e.target.value)} className={cellInput} />
                    </td>
                    <td className={tdClass}>
                      <input
                        type="number"
                        min={0}
                        value={row.quantityReceived}
                        onChange={(e) => update(idx, "quantityReceived", Number(e.target.value))}
                        className={`${cellInput} text-right`}
                      />
                    </td>
                    <td className={tdClass}>
                      <input
                        type="number"
                        min={0}
                        value={row.quantityRejected}
                        onChange={(e) => update(idx, "quantityRejected", Number(e.target.value))}
                        className={`${cellInput} text-right`}
                      />
                    </td>
                    <td className={tdClass}>
                      <div className="flex items-center gap-1">
                        <input
                          type="number"
                          readOnly
                          value={row.quantityAccepted}
                          className={`${cellInput} bg-green-50 text-green-700 font-medium text-right cursor-default`}
                        />
                      </div>
                    </td>
                    <td className={tdClass}>
                      <input type="text" value={row.remarks} onChange={(e) => update(idx, "remarks", e.target.value)} className={cellInput} />
                    </td>
                    <td className={tdClass}>
                      <button onClick={() => deleteRow(idx)} className="text-slate-300 hover:text-red-500 transition-colors p-1">
                        <Trash2 className="w-3.5 h-3.5" />
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
      </div>
    </div>
  )
}
