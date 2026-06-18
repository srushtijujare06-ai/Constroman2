'use client'

import { useParams } from "next/navigation"
import Header from "@/components/layout/Header"
import RegisterTable from "@/components/forms/RegisterTable"
import { siteDiaryEntries, projects } from "@/lib/mock-data"
import type { Column } from "@/components/forms/RegisterTable"

const columns: Column[] = [
  { key: "srNo", label: "Sr. No", type: "number", width: "70px" },
  { key: "date", label: "Date", type: "date", width: "130px" },
  { key: "details", label: "Details", type: "textarea", width: "320px" },
  { key: "remarks", label: "Remarks", type: "text", width: "200px" },
]

export default function SiteDiaryPage() {
  const params = useParams<{ projectId: string }>()
  const projectId = params.projectId
  const project = projects.find((p) => p.id === projectId)
  const data = siteDiaryEntries[projectId] ?? []

  return (
    <div className="min-h-full bg-gray-50">
      <Header title="Site Diary" subtitle={project?.name ?? projectId} />
      <div className="p-6">
        <RegisterTable
          title="Site Diary Register"
          columns={columns}
          initialData={data}
        />
      </div>
    </div>
  )
}
