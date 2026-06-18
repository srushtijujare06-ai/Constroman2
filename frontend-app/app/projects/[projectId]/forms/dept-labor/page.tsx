'use client'

import { useParams } from "next/navigation"
import Header from "@/components/layout/Header"
import RegisterTable from "@/components/forms/RegisterTable"
import { deptLaborEntries, projects } from "@/lib/mock-data"
import type { Column } from "@/components/forms/RegisterTable"

const columns: Column[] = [
  { key: "srNo", label: "Sr. No", type: "number", width: "70px" },
  { key: "date", label: "Date", type: "date", width: "120px" },
  { key: "challanNo", label: "Challan No", type: "text", width: "130px" },
  { key: "subContractorName", label: "Sub-Contractor Name", type: "text", width: "190px" },
  { key: "nameOfLabor", label: "Name of Labor", type: "text", width: "150px" },
  { key: "labourCategory", label: "Labour Category", type: "text", width: "140px" },
  { key: "noOfMandays", label: "No. of Mandays", type: "number", width: "120px" },
  { key: "workdoneDetails", label: "Workdone Details", type: "textarea", width: "200px" },
  { key: "approxQuantity", label: "Approx Qty", type: "text", width: "110px" },
  { key: "unit", label: "Unit", type: "text", width: "80px" },
  { key: "recoveryFrom", label: "Recovery From", type: "text", width: "150px" },
  { key: "recoveryRate", label: "Recovery Rate", type: "text", width: "120px" },
  { key: "recoveryAmount", label: "Recovery Amount", type: "text", width: "140px" },
  { key: "authorisedBy", label: "Authorised By", type: "text", width: "130px" },
  { key: "debitDetails", label: "Debit Details", type: "text", width: "160px" },
  { key: "remarks", label: "Remarks", type: "text", width: "160px" },
]

export default function DeptLaborPage() {
  const params = useParams<{ projectId: string }>()
  const projectId = params.projectId
  const project = projects.find((p) => p.id === projectId)
  const data = deptLaborEntries[projectId] ?? []

  return (
    <div className="min-h-full bg-gray-50">
      <Header title="Departmental Labour Register" subtitle={project?.name ?? projectId} />
      <div className="p-6">
        <RegisterTable
          title="Departmental Labour Register"
          columns={columns}
          initialData={data}
        />
      </div>
    </div>
  )
}
