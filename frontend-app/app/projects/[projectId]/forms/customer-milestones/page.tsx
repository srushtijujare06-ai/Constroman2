'use client'

import { useParams } from "next/navigation"
import Header from "@/components/layout/Header"
import RegisterTable from "@/components/forms/RegisterTable"
import { customerMilestoneEntries, projects } from "@/lib/mock-data"
import type { Column } from "@/components/forms/RegisterTable"

const columns: Column[] = [
  { key: "date", label: "Date", type: "date", width: "130px" },
  { key: "customerMilestone", label: "Customer Milestone", type: "text", width: "240px" },
  { key: "activity", label: "Activity", type: "text", width: "200px" },
  { key: "workCompletedPercent", label: "Work Completed Today (%)", type: "number", width: "170px" },
  { key: "contractor", label: "Contractor", type: "text", width: "200px" },
]

export default function CustomerMilestonesPage() {
  const params = useParams<{ projectId: string }>()
  const projectId = params.projectId
  const project = projects.find((p) => p.id === projectId)
  const data = customerMilestoneEntries[projectId] ?? []

  return (
    <div className="min-h-full bg-gray-50">
      <Header title="Customer Milestones" subtitle={project?.name ?? projectId} />
      <div className="p-6">
        <RegisterTable
          title="Customer Milestone Register"
          columns={columns}
          initialData={data}
        />
      </div>
    </div>
  )
}
