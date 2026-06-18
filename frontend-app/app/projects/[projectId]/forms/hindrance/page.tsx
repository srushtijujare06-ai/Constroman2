'use client'

import { useParams } from "next/navigation"
import Header from "@/components/layout/Header"
import RegisterTable from "@/components/forms/RegisterTable"
import { hindranceEntries, projects } from "@/lib/mock-data"
import type { Column } from "@/components/forms/RegisterTable"

const columns: Column[] = [
  { key: "srNo", label: "Sr. No", type: "number", width: "70px" },
  { key: "date", label: "Date", type: "date", width: "120px" },
  { key: "hindranceDetails", label: "Hindrance Details", type: "textarea", width: "220px" },
  { key: "itemsAffected", label: "Items Affected", type: "textarea", width: "180px" },
  { key: "dateOfRecording", label: "Date of Recording", type: "date", width: "140px" },
  { key: "startDate", label: "Start Date", type: "date", width: "120px" },
  { key: "closureDate", label: "Closure Date", type: "date", width: "120px" },
  { key: "totalPeriod", label: "Total Period (days)", type: "text", width: "130px" },
  { key: "overlappingPeriod", label: "Overlapping Period", type: "text", width: "140px" },
  { key: "netHindranceDays", label: "Net Hindrance Days", type: "text", width: "140px" },
  { key: "approvedBy", label: "Approved By", type: "text", width: "130px" },
  { key: "remarks", label: "Remarks", type: "text", width: "180px" },
]

export default function HindrancePage() {
  const params = useParams<{ projectId: string }>()
  const projectId = params.projectId
  const project = projects.find((p) => p.id === projectId)
  const data = hindranceEntries[projectId] ?? []

  return (
    <div className="min-h-full bg-gray-50">
      <Header title="Hindrance Register" subtitle={project?.name ?? projectId} />
      <div className="p-6">
        <RegisterTable
          title="Hindrance Register"
          columns={columns}
          initialData={data}
        />
      </div>
    </div>
  )
}
