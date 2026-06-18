export type Project = {
  id: string
  name: string
  location: string
  startDate: string
  status: 'active' | 'completed' | 'on-hold'
  subProjects?: Project[]
}

export type WeatherEntry = {
  id: string
  date: string
  tempAt12PM: number
  rainStart: string
  rainEnd: string
  remarks: string
}

export type SiteDiaryEntry = {
  id: string
  srNo: number
  date: string
  details: string
  remarks: string
}

export type HindranceEntry = {
  id: string
  srNo: number
  date: string
  hindranceDetails: string
  itemsAffected: string
  dateOfRecording: string
  startDate: string
  closureDate: string
  totalPeriod: string
  overlappingPeriod: string
  netHindranceDays: string
  approvedBy: string
  remarks: string
}

export type CustomerMilestoneEntry = {
  id: string
  date: string
  customerMilestone: string
  activity: string
  workCompletedPercent: number
  contractor: string
}

export type ConstructionMilestoneEntry = {
  id: string
  date: string
  constructionMilestone: string
  activity: string
  workCompletedPercent: number
  contractor: string
}

export type WorkLaborEntry = {
  id: string
  date: string
  milestone: string
  activity: string
  workCompleted: string
  unit: string
  contractor: string
  category: string
  noOfLabors: number
  remarks: string
}

export type DeptLaborEntry = {
  id: string
  srNo: number
  date: string
  challanNo: string
  subContractorName: string
  nameOfLabor: string
  labourCategory: string
  noOfMandays: number
  workdoneDetails: string
  approxQuantity: string
  unit: string
  recoveryFrom: string
  recoveryRate: string
  recoveryAmount: string
  authorisedBy: string
  debitDetails: string
  remarks: string
}

export type MaterialReceiptEntry = {
  id: string
  srNo: number
  date: string
  timeIn: string
  poNo: string
  grnNo: string
  materialDescription: string
  unit: string
  supplier: string
  quantityReceived: number
  quantityRejected: number
  quantityAccepted: number
  remarks: string
}

export type WorkItem = {
  id: string
  itemNo: string
  description: string
  carpenter: number
  fitter: number
  helper: number
  mason: number
  skilled: number
  unskilled: number
}

export type MaterialReceiptReportEntry = {
  id: string
  itemNo: string
  materialDescription: string
  unit: string
  supplierName: string
  challanNo: string
  previous: number
  today: number
  cumulative: number
}

export type SiteReport = {
  id: string
  projectId: string
  date: string
  rainFrom: string
  rainTo: string
  workItems: WorkItem[]
  remarks: string
  rmcPreviousReceipt: string
  rmcTodaysReceipt: string
  rmcCumulativeReceipt: string
  rmcOpeningBalance: string
  rmcTodaysConsumption: string
  rmcClosingBalance: string
  reinfPreviousReceipt: string
  reinfTodaysReceipt: string
  reinfCumulativeReceipt: string
  reinfOpeningBalance: string
  reinfTodaysConsumption: string
  reinfClosingBalance: string
  decisionsPending: string
  milestonesAchieved: string
  materialReceiptReport: MaterialReceiptReportEntry[]
  siteVisitors: string
  preparedBy: string
  siteIncharge: string
}
