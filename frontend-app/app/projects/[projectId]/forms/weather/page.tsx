'use client'

import { useParams } from "next/navigation"
import Header from "@/components/layout/Header"
import RegisterTable from "@/components/forms/RegisterTable"
import { weatherEntries, projects } from "@/lib/mock-data"
import type { Column } from "@/components/forms/RegisterTable"

const columns: Column[] = [
  { key: "date", label: "Date", type: "date", width: "130px" },
  { key: "tempAt12PM", label: "Temp @12PM (°C)", type: "number", width: "130px" },
  { key: "rainStart", label: "Rain Start", type: "time", width: "110px" },
  { key: "rainEnd", label: "Rain End", type: "time", width: "110px" },
  { key: "remarks", label: "Remarks", type: "textarea", width: "240px" },
]

export default function WeatherPage() {
  const params = useParams<{ projectId: string }>()
  const projectId = params.projectId
  const project = projects.find((p) => p.id === projectId)
  const data = weatherEntries[projectId] ?? []

  return (
    <div className="min-h-full bg-gray-50">
      <Header title="Weather Log" subtitle={project?.name ?? projectId} />
      <div className="p-6">
        <RegisterTable
          title="Weather Log Register"
          columns={columns}
          initialData={data}
        />
      </div>
    </div>
  )
}
