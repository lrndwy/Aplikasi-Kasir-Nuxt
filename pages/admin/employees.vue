<template>
  <div class="flex flex-col min-h-screen bg-gray-100 dark:bg-gray-900 p-2 sm:p-4">
    <h1 class="text-2xl sm:text-3xl font-bold mb-4 sm:mb-6 text-gray-900 dark:text-white">
      Manajemen Karyawan
    </h1>

    <div v-if="pageLoading" class="flex justify-center items-center h-64">
      <div class="spinner"></div>
    </div>

    <div
      v-else-if="!hasAdminRole"
      class="text-center text-red-500 dark:text-red-400"
    >
      Anda tidak memiliki izin untuk mengakses halaman ini.
    </div>

    <div v-else>

      <!-- Daftar Karyawan -->
      <Card>
        <CardHeader>
          <CardTitle>Daftar Karyawan</CardTitle>
        </CardHeader>
        <CardContent>
          <div class="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead class="min-w-[150px]">Email</TableHead>
                  <TableHead class="min-w-[200px] hidden md:table-cell">Nama Lengkap</TableHead>
                  <TableHead class="min-w-[80px]">Peran</TableHead>
                  <TableHead class="min-w-[150px] hidden lg:table-cell">Telepon</TableHead>
                  <TableHead class="min-w-[200px] hidden xl:table-cell">Alamat</TableHead>
                  <TableHead class="min-w-[80px]">Aktif</TableHead>
                  <TableHead class="min-w-[150px] hidden md:table-cell">Dibuat Pada</TableHead>
                  <TableHead class="min-w-[150px] hidden md:table-cell">Diperbarui Pada</TableHead>
                  <TableHead class="min-w-[150px]">Aksi</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                <TableRow v-for="employee in employees" :key="employee.id" @click="showEmployeeDetail(employee)" class="cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-700">
                  <TableCell>{{ employee.email }}</TableCell>
                  <TableCell class="hidden md:table-cell">{{ employee.full_name }}</TableCell>
                  <TableCell>{{ employee.role }}</TableCell>
                  <TableCell class="hidden lg:table-cell">{{ employee.phone || '-' }}</TableCell>
                  <TableCell class="hidden xl:table-cell">{{ employee.address || '-' }}</TableCell>
                  <TableCell>
                    <Badge :variant="employee.is_active ? 'success' : 'destructive'">
                      {{ employee.is_active ? "Ya" : "Tidak" }}
                    </Badge>
                  </TableCell>
                  <TableCell class="hidden md:table-cell">{{ formatDate(employee.created_at) }}</TableCell>
                  <TableCell class="hidden md:table-cell">{{ formatDate(employee.updated_at) }}</TableCell>
                  <TableCell @click.stop>
                    <DropdownMenu>
                      <DropdownMenuTrigger as-child>
                        <Button variant="ghost" class="h-8 w-8 p-0">
                          <span class="sr-only">Open menu</span>
                          <MoreHorizontal class="h-4 w-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuLabel>Aksi</DropdownMenuLabel>
                        <DropdownMenuItem @click="showEmployeeDetail(employee)">
                          <Info class="mr-2 h-4 w-4" />Detail
                        </DropdownMenuItem>
                        <DropdownMenuItem @click="editEmployee(employee)">
                          <Edit class="mr-2 h-4 w-4" />Edit
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </TableCell>
                </TableRow>
              </TableBody>
            </Table>
          </div>
          <div
            v-if="employees.length === 0 && !loadingEmployees"
            class="text-center text-gray-500 dark:text-gray-400 mt-4"
          >
            Tidak ada karyawan ditemukan.
          </div>
        </CardContent>
      </Card>


      <!-- Employee Detail Dialog -->
      <Dialog :open="isEmployeeDetailOpen" @update:open="isEmployeeDetailOpen = $event">
        <DialogContent class="sm:max-w-[425px]">
          <DialogHeader>
            <DialogTitle>Detail Karyawan</DialogTitle>
            <DialogDescription>Informasi lengkap mengenai karyawan ini.</DialogDescription>
          </DialogHeader>
          <div v-if="selectedEmployee" class="grid gap-4 py-4">
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailEmail" class="text-right">Email</Label>
              <Input id="detailEmail" :model-value="selectedEmployee.email" readonly class="col-span-3" />
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailFullName" class="text-right">Nama Lengkap</Label>
              <Input id="detailFullName" :model-value="selectedEmployee.full_name || 'Tidak ada nama lengkap'" readonly class="col-span-3" />
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailRole" class="text-right">Peran</Label>
              <Input id="detailRole" :model-value="selectedEmployee.role" readonly class="col-span-3" />
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailPhone" class="text-right">Telepon</Label>
              <Input id="detailPhone" :model-value="selectedEmployee.phone || 'Tidak ada nomor telepon'" readonly class="col-span-3" />
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailAddress" class="text-right">Alamat</Label>
              <Textarea id="detailAddress" :model-value="selectedEmployee.address || 'Tidak ada alamat'" readonly class="col-span-3" />
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailIsActive" class="text-right">Aktif</Label>
              <div class="col-span-3">
                <Badge :variant="selectedEmployee.is_active ? 'success' : 'destructive'">
                  {{ selectedEmployee.is_active ? "Ya" : "Tidak" }}
                </Badge>
              </div>
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailCreatedAt" class="text-right">Dibuat Pada</Label>
              <Input id="detailCreatedAt" :model-value="formatDate(selectedEmployee.created_at)" readonly class="col-span-3" />
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailUpdatedAt" class="text-right">Diperbarui Pada</Label>
              <Input id="detailUpdatedAt" :model-value="formatDate(selectedEmployee.updated_at)" readonly class="col-span-3" />
            </div>
          </div>
          <DialogFooter>
            <DialogClose as-child>
              <Button type="button" variant="outline">Tutup</Button>
            </DialogClose>
            <Button @click="editEmployee(selectedEmployee!)">
              <Edit class="mr-2 h-4 w-4" />Edit Karyawan
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
    <Toaster />
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  title: 'Employees - Aplikasi Kasir'
})
import { ref, onMounted, watch } from "vue";
import { useRouter } from "vue-router";
import { useSupabaseClient, useSupabaseUser } from "#imports";
import { toast } from 'vue-sonner';
import { Toaster } from '@/components/ui/sonner';
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Checkbox } from "@/components/ui/checkbox";
import { Badge } from "@/components/ui/badge";
import 'vue-sonner/style.css';
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
  DialogClose,
} from "@/components/ui/dialog";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { MoreHorizontal, Edit, Info } from "lucide-vue-next";
import type { User } from "@supabase/supabase-js";

interface UserProfile {
  id: string;
  email: string;
  full_name: string | null;
  role: "admin" | "manager" | "cashier";
  phone: string | null;
  address: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

const supabase = useSupabaseClient();
const user = useSupabaseUser();
const router = useRouter();

const userProfile = ref<UserProfile | null>(null);
const employees = ref<UserProfile[]>([]);
const loadingEmployees = ref(true);
const loading = ref(false); // Renamed from loadingAddEmployee

const isEmployeeFormOpen = ref(false); // Controls the add/edit employee dialog
const isEditingEmployee = ref(false); // True if editing an existing employee, false if adding new
const employeeForm = ref({
  id: "",
  email: "",
  full_name: "",
  role: "cashier" as "admin" | "manager" | "cashier",
  phone: "",
  address: "",
  is_active: true,
});
const isEmployeeDetailOpen = ref(false); // Controls the employee detail dialog
const selectedEmployee = ref<UserProfile | null>(null); // Stores the selected employee for detail view

const fetchUserProfile = async (userId: string) => {
  const { data, error } = await supabase
    .from("profiles")
    .select("*")
    .eq("id", userId)
    .single();

  if (error) {
    console.error("Error fetching user profile:", error.message);
    userProfile.value = null;
  } else {
    userProfile.value = data as UserProfile;
  }
};

const fetchEmployees = async () => {
  loadingEmployees.value = true;
  try {
    const { data, error } = await supabase
      .from("profiles")
      .select("*")
      .order("created_at", { ascending: false });

    if (error) throw error;
    employees.value = data as UserProfile[];
  } catch (error: any) {
    toast.error("Gagal memuat data karyawan!", {
      description: error.message,
    });
  } finally {
    loadingEmployees.value = false;
  }
};

const saveEmployee = async () => {
  loading.value = true;
  try {
    const { error } = await supabase
      .from("profiles")
      .update({
        full_name: employeeForm.value.full_name,
        phone: employeeForm.value.phone,
        address: employeeForm.value.address,
        role: employeeForm.value.role,
        is_active: employeeForm.value.is_active,
        updated_at: new Date().toISOString(), // Add updated_at
      })
      .eq("id", employeeForm.value.id);

    if (error) throw error;
    toast.success("Karyawan berhasil diperbarui!", {
      description: `Karyawan ${employeeForm.value.full_name || employeeForm.value.email} telah berhasil diperbarui.`,
    });
    await fetchEmployees();
    resetForm();
    isEmployeeFormOpen.value = false; // Close the dialog on success
  } catch (error: any) {
    toast.error("Gagal menyimpan karyawan!", {
      description: error.message,
    });
  } finally {
    loading.value = false;
  }
};


const editEmployee = (employee: UserProfile) => {
  isEditingEmployee.value = true;
  employeeForm.value = {
    ...employee,
    is_active: Boolean(employee.is_active), // Ensure is_active is a boolean
  };
  isEmployeeFormOpen.value = true; // Open the dialog for editing
  isEmployeeDetailOpen.value = false; // Close detail dialog if open
};

const showEmployeeDetail = (employee: UserProfile) => {
  selectedEmployee.value = employee;
  isEmployeeDetailOpen.value = true;
};

const cancelEditEmployee = () => {
  resetForm();
  isEmployeeFormOpen.value = false; // Close the dialog on cancel
};



const resetForm = () => {
  isEditingEmployee.value = false;
  employeeForm.value = {
    id: "",
    email: "",
    full_name: "",
    role: "cashier",
    phone: "",
    address: "",
    is_active: true,
  };
};

const pageLoading = ref(true); // Controls the loading state for the entire page
const hasAdminRole = ref(false);

const checkUserRole = async () => {
  if (!user.value) {
    hasAdminRole.value = false;
    return;
  }
  const { data, error } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.value.id)
    .single();

  if (error) {
    toast.error("Gagal memeriksa peran pengguna!", {
      description: error.message,
    });
    hasAdminRole.value = false;
    return;
  }
  if (!data) {
    toast.error("Data profil pengguna tidak ditemukan.");
    hasAdminRole.value = false;
    return;
  }
  hasAdminRole.value = data?.role === "admin";
  if (!hasAdminRole.value) {
    toast.warning("Anda tidak memiliki izin untuk mengakses halaman ini.", {
      description: "Silakan hubungi administrator untuk mendapatkan akses.",
    });
  }
};

onMounted(async () => {
  pageLoading.value = true; // Start loading state
  try {
    await checkUserRole();
    if (hasAdminRole.value === true) {
      await fetchEmployees();
    }
  } catch (error: any) {
    toast.error("Terjadi kesalahan saat memuat data awal!", {
      description: error.message,
    });
  } finally {
    pageLoading.value = false; // End loading state
  }
});

watch(user, async (newUser) => {
  if (newUser) {
    try {
      await checkUserRole();
      if (hasAdminRole.value) {
        await fetchEmployees();
      }
    } catch (error: any) {
      toast.error("Terjadi kesalahan saat memperbarui data pengguna!", {
        description: error.message,
      });
    }
  } else {
    hasAdminRole.value = false;
    employees.value = [];
    router.push("/login");
  }
});

const formatDate = (dateString: string) => {
  const options: Intl.DateTimeFormatOptions = {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  };
  return new Date(dateString).toLocaleDateString("id-ID", options);
};
</script>

<style scoped>
.spinner {
  border: 4px solid rgba(0, 0, 0, 0.1);
  width: 36px;
  height: 36px;
  border-radius: 50%;
  border-left-color: #09f;
  animation: spin 1s ease infinite;
}

@keyframes spin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}
</style>
