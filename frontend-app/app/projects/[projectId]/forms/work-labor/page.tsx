'use client'

import { useParams } from "next/navigation"
import Header from "@/components/layout/Header"
import RegisterTable from "@/components/forms/RegisterTable"
import { workLaborEntries, projects } from "@/lib/mock-data"
import type { Column } from "@/components/forms/RegisterTable"

const columns: Column[] = [
  { key: "date", label: "Date", type: "date", width: "120px" },
  { key: "milestone", label: "Milestone", type: "text", width: "180px" },
  { key: "activity", label: "Activity", type: "text", width: "180px" },
  { key: "workCompleted", label: "Work Completed", type: "text", width: "130px" },
  { key: "unit", label: "Unit", type: "text", width: "90px" },
  { key: "contractor", label: "Contractor", type: "text", width: "180px" },
  { key: "category", label: "Category", type: "text", width: "120px" },
  { key: "noOfLabors", label: "No. of Labors", type: "number", width: "110px" },
  { key: "remarks", label: "Remarks", type: "text", width: "180px" },
]

export default function WorkLaborPage() {
  const params = useParams<{ projectId: string }>()
  const projectId = params.projectId
  const project = projects.find((p) => p.id === projectId)
  const data = workLaborEntries[projectId] ?? []

  return (
    <div className="min-h-full bg-gray-50">
      <Header title="Work & Labour" subtitle={project?.name ?? projectId} />
      <div className="p-6">
        <RegisterTable
          title="Work & Labour Register"
          columns={columns}
          initialData={data}
        />
      </div>
    </div>
  )
}
